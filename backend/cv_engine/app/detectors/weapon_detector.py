"""
SecureCity AI — Weapon Detector

Two honest, separately-tracked layers rather than one that pretends to
cover firearms it can't see:

1. Bladed/blunt weapons — real today. Stock YOLOv11 is trained on COCO,
   which includes `knife`, `scissors`, and `baseball bat` as real classes,
   so this layer just filters/labels YOLODetector's existing output — no
   custom model needed.
2. Firearms — COCO has no `gun`/`pistol`/`rifle` class, so this layer only
   activates if a custom fine-tuned model is supplied via `WEAPON_MODEL_PATH`
   (see app/training/train_yolo.py). Until then it stays honestly
   `loaded: False` instead of silently returning "no weapon found" in a way
   that looks the same as a clean scene.
"""

from __future__ import annotations

import os
from typing import Any

import numpy as np
from loguru import logger

from app.detectors.base_detector import BaseDetector, Detection

BLADED_BLUNT_CLASSES = {"knife", "scissors", "baseball bat"}


class WeaponDetector(BaseDetector):
    """Combines COCO-proxy bladed-weapon detection with an optional custom firearm model."""

    def __init__(
        self,
        confidence_threshold: float = 0.45,
        weapon_model_path: str | None = None,
        device: str = "cpu",
    ) -> None:
        super().__init__(confidence_threshold)
        self._device = device
        self._weapon_model_path = weapon_model_path or os.environ.get("WEAPON_MODEL_PATH")
        self._firearm_model = None
        self._firearm_class_names: list[str] = []
        self._load_firearm_model()

    def _load_firearm_model(self) -> None:
        if not self._weapon_model_path or not os.path.exists(self._weapon_model_path):
            logger.info(
                "No WEAPON_MODEL_PATH configured — firearm detection is inactive. "
                "Bladed/blunt weapon detection (knife/scissors/baseball bat) still runs "
                "via the base YOLO model. See app/training/train_yolo.py to fine-tune a "
                "firearm model once a real annotated dataset is available."
            )
            return

        try:
            from ultralytics import YOLO
            self._firearm_model = YOLO(self._weapon_model_path)
            self._firearm_model.to(self._device)
            self._firearm_class_names = list(self._firearm_model.names.values())
            logger.info(f"✅ Firearm detection model loaded: {self._weapon_model_path}")
        except Exception as exc:
            logger.warning(f"Firearm model load failed: {exc}")
            self._firearm_model = None

    def detect(self, frame: np.ndarray) -> list[Detection]:
        """Not used directly — use analyze() with the frame and YOLO detections."""
        return []

    def analyze(
        self,
        frame: np.ndarray,
        yolo_detections: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """
        Combine bladed/blunt weapon detections (from the already-computed
        YOLO pass) with a firearm pass (if a custom model is loaded).
        """
        bladed = [
            d for d in yolo_detections
            if d.get("class_name") in BLADED_BLUNT_CLASSES and d.get("confidence", 0) >= self._confidence_threshold
        ]

        firearms: list[dict[str, Any]] = []
        if self._firearm_model is not None:
            firearms = self._detect_firearms(frame)

        weapons_found = bladed + firearms
        self._increment_stats(len(weapons_found))

        return {
            "weapon_detected": len(weapons_found) > 0,
            "weapons": weapons_found,
            "bladed_blunt_count": len(bladed),
            "firearm_count": len(firearms),
            "firearm_model_loaded": self._firearm_model is not None,
        }

    def _detect_firearms(self, frame: np.ndarray) -> list[dict[str, Any]]:
        try:
            results = self._firearm_model(frame, conf=self._confidence_threshold, verbose=False)[0]
            firearms = []
            for box in results.boxes:
                class_id = int(box.cls[0])
                class_name = (
                    self._firearm_class_names[class_id]
                    if class_id < len(self._firearm_class_names) else "firearm"
                )
                firearms.append(Detection(
                    class_name=class_name,
                    confidence=float(box.conf[0]),
                    bbox=box.xyxy[0].tolist(),
                    attributes={"is_security_threat": True, "weapon_layer": "firearm"},
                ).to_dict())
            return firearms
        except Exception as exc:
            logger.error(f"Firearm detection error: {exc}")
            return []

    def get_detection_type(self) -> str:
        return "WeaponDetector"

    def get_status(self) -> dict[str, Any]:
        return {
            "bladed_blunt_detection": "active (base YOLO COCO classes: knife, scissors, baseball bat)",
            "firearm_model_loaded": self._firearm_model is not None,
            "firearm_model_path": self._weapon_model_path,
        }

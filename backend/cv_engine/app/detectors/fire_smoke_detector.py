"""
SecureCity AI — Fire & Smoke Detector

Classical-CV-first, not ML-first: COCO (the stock YOLOv11 base model) has
no `fire`/`smoke` classes, and there is no legitimate way to fabricate
photographs of real fires to train on in this environment. Rather than
silently detecting nothing behind a base model that can never match those
classes, this detector uses well-established, training-free techniques:

- Fire: HSV color thresholding for orange/red/yellow regions, combined
  with frame-to-frame flicker analysis (fire's brightness varies rapidly;
  a static red object's doesn't) to cut down false positives.
- Smoke: HSV thresholding for desaturated grey regions, combined with an
  edge-density check (smoke blurs detail underneath it; a plain grey wall
  or road does not lose edges over time the same way).

A secondary YOLO pass runs *in addition* if a custom fine-tuned model is
supplied via `FIRE_MODEL_PATH` (see app/training/train_yolo.py) — this is
additive, not a replacement, since the classical path works today with no
training data at all.
"""

from __future__ import annotations

import os
from collections import deque
from typing import Any

import numpy as np
from loguru import logger

from app.detectors.base_detector import BaseDetector, Detection

# Fire: orange/red/yellow in HSV. Hue wraps near 0/180 for red, so this
# range intentionally leans toward orange-yellow (0-35) to reduce false
# positives on generic red objects (e.g. red clothing, brake lights).
FIRE_HSV_LOWER = np.array([0, 60, 80], dtype=np.uint8)
FIRE_HSV_UPPER = np.array([35, 255, 255], dtype=np.uint8)

# Smoke: low-saturation grey/white regions, mid-to-high brightness.
SMOKE_HSV_LOWER = np.array([0, 0, 80], dtype=np.uint8)
SMOKE_HSV_UPPER = np.array([180, 60, 220], dtype=np.uint8)


class FireSmokeDetector(BaseDetector):
    """Classical HSV+flicker/edge-density fire & smoke detector, with an optional custom-model boost."""

    def __init__(
        self,
        confidence_threshold: float = 0.5,
        fire_area_ratio_threshold: float = 0.02,
        smoke_area_ratio_threshold: float = 0.05,
        flicker_window: int = 6,
        device: str = "cpu",
    ) -> None:
        super().__init__(confidence_threshold)
        self._fire_area_ratio_threshold = fire_area_ratio_threshold
        self._smoke_area_ratio_threshold = smoke_area_ratio_threshold
        self._flicker_window = flicker_window
        self._fire_intensity_history: dict[str, deque[float]] = {}
        self._device = device
        self._model = None
        self._class_names: list[str] = []
        self._load_optional_model()

    def _load_optional_model(self) -> None:
        fire_model_path = os.environ.get("FIRE_MODEL_PATH")
        if not fire_model_path or not os.path.exists(fire_model_path):
            logger.info(
                "No FIRE_MODEL_PATH configured — using classical HSV+flicker/"
                "edge-density fire & smoke detection only (no training data required)."
            )
            return
        try:
            from ultralytics import YOLO
            self._model = YOLO(fire_model_path)
            self._model.to(self._device)
            self._class_names = list(self._model.names.values())
            logger.info(f"✅ Custom fire/smoke model loaded: {fire_model_path}")
        except Exception as exc:
            logger.warning(f"Fire/smoke model load failed: {exc}")
            self._model = None

    def detect(self, frame: np.ndarray) -> list[Detection]:
        """BaseDetector-compliant entry point — delegates to analyze()."""
        return self.analyze(frame)["detections"]

    def analyze(self, frame: np.ndarray, camera_id: str = "default") -> dict[str, Any]:
        """
        Run fire and smoke detection on a single frame.

        `camera_id` scopes the flicker-history buffer — without it, frames
        from different cameras would corrupt each other's flicker signal.
        """
        import cv2

        detections: list[dict[str, Any]] = []

        fire_hit = self._detect_fire_classical(frame, camera_id, cv2)
        if fire_hit:
            detections.append(fire_hit)

        smoke_hit = self._detect_smoke_classical(frame, cv2)
        if smoke_hit:
            detections.append(smoke_hit)

        if self._model is not None:
            detections.extend(self._detect_yolo(frame))

        self._increment_stats(len(detections))

        return {
            "detected": len(detections) > 0,
            "confidence": max((d["confidence"] for d in detections), default=0.0),
            "detections": detections,
        }

    def _detect_fire_classical(self, frame: np.ndarray, camera_id: str, cv2: Any) -> dict[str, Any] | None:
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, FIRE_HSV_LOWER, FIRE_HSV_UPPER)
        area_ratio = cv2.countNonZero(mask) / (frame.shape[0] * frame.shape[1])

        history = self._fire_intensity_history.setdefault(camera_id, deque(maxlen=self._flicker_window))
        history.append(area_ratio)

        if area_ratio < self._fire_area_ratio_threshold:
            return None

        # Fire flickers frame-to-frame; a static red/orange object doesn't.
        flicker_score = float(np.std(history)) if len(history) >= 3 else 0.0
        is_flickering = flicker_score > (area_ratio * 0.15)

        confidence = min(1.0, area_ratio * 5.0 + (0.2 if is_flickering else 0.0))
        if confidence < self._confidence_threshold:
            return None

        bbox = self._mask_bbox(mask)
        return Detection(
            class_name="fire",
            confidence=round(confidence, 3),
            bbox=bbox,
            attributes={
                "detection_method": "classical_hsv_flicker",
                "area_ratio": round(area_ratio, 4),
                "flicker_score": round(flicker_score, 4),
                "intensity": self._estimate_intensity(area_ratio),
                "is_security_threat": True,
            },
        ).to_dict()

    def _detect_smoke_classical(self, frame: np.ndarray, cv2: Any) -> dict[str, Any] | None:
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, SMOKE_HSV_LOWER, SMOKE_HSV_UPPER)
        area_ratio = cv2.countNonZero(mask) / (frame.shape[0] * frame.shape[1])

        if area_ratio < self._smoke_area_ratio_threshold:
            return None

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        edges = cv2.Canny(gray, 50, 150)
        masked_edges = cv2.bitwise_and(edges, edges, mask=mask)
        mask_pixel_count = max(cv2.countNonZero(mask), 1)
        edge_density = cv2.countNonZero(masked_edges) / mask_pixel_count

        # Smoke blurs the detail underneath it — a plain grey surface with
        # sharp edges (road markings, a wall) is not smoke.
        if edge_density > 0.15:
            return None

        confidence = min(1.0, area_ratio * 3.0 + (0.15 - edge_density))
        if confidence < self._confidence_threshold:
            return None

        bbox = self._mask_bbox(mask)
        return Detection(
            class_name="smoke",
            confidence=round(confidence, 3),
            bbox=bbox,
            attributes={
                "detection_method": "classical_hsv_edge_density",
                "area_ratio": round(area_ratio, 4),
                "edge_density": round(edge_density, 4),
                "is_security_threat": True,
            },
        ).to_dict()

    def _detect_yolo(self, frame: np.ndarray) -> list[dict[str, Any]]:
        try:
            results = self._model(frame, conf=self._confidence_threshold, verbose=False)[0]
            out = []
            for box in results.boxes:
                class_name = results.names[int(box.cls[0])]
                if class_name in ("fire", "smoke"):
                    out.append(Detection(
                        class_name=class_name,
                        confidence=float(box.conf[0]),
                        bbox=box.xyxy[0].tolist(),
                        attributes={"detection_method": "custom_yolo", "is_security_threat": True},
                    ).to_dict())
            return out
        except Exception as exc:
            logger.error(f"Fire/smoke custom-model detection error: {exc}")
            return []

    def _mask_bbox(self, mask: np.ndarray) -> list[float]:
        ys, xs = np.where(mask > 0)
        if len(xs) == 0:
            return [0.0, 0.0, 0.0, 0.0]
        return [float(xs.min()), float(ys.min()), float(xs.max()), float(ys.max())]

    def _estimate_intensity(self, area_ratio: float) -> str:
        if area_ratio > 0.3:
            return "severe"
        elif area_ratio > 0.1:
            return "moderate"
        return "minor"

    def get_detection_type(self) -> str:
        return "FireSmokeDetector"

    def get_status(self) -> dict[str, Any]:
        return {
            "classical_detection": "active (HSV color + flicker/edge-density heuristics, no training data required)",
            "custom_model_loaded": self._model is not None,
        }


__all__ = ["FireSmokeDetector"]

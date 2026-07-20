"""
SecureCity AI — YOLOv11 Object Detector
Uses Ultralytics with ByteTracker for multi-object tracking.
"""

from __future__ import annotations

from typing import Any

import numpy as np
from loguru import logger

from app.detectors.base_detector import BaseDetector, Detection

# Detection classes of interest for security
SECURITY_CLASSES = {
    "person", "car", "truck", "motorcycle", "bus",
    "bicycle", "fire", "smoke", "knife", "gun", "weapon",
}

# Class-to-priority mapping
CLASS_PRIORITY = {
    "weapon": 5, "gun": 5, "knife": 5,
    "fire": 4, "smoke": 4,
    "person": 2, "car": 1, "truck": 1,
    "motorcycle": 1, "bus": 1, "bicycle": 1,
}


class YOLODetector(BaseDetector):
    """
    YOLOv11 object detector with ByteTracker multi-object tracking.

    Supports detection of persons, vehicles, and security-relevant objects.
    Falls back gracefully if ultralytics is not available.
    """

    DEFAULT_CLASSES = [
        "person", "bicycle", "car", "motorcycle", "bus", "truck",
        "fire", "smoke", "weapon", "knife",
    ]

    def __init__(
        self,
        model_path: str = "yolo11n.pt",
        confidence_threshold: float = 0.45,
        iou_threshold: float = 0.45,
        device: str = "cpu",
        max_detections: int = 300,
    ) -> None:
        super().__init__(confidence_threshold)
        self._model_path = model_path
        self._iou_threshold = iou_threshold
        self._device = device
        self._max_detections = max_detections
        self._model = None
        self._tracker = None
        self._class_names: list[str] = []
        self._load_model()

    def _load_model(self) -> None:
        """Load YOLOv11 model."""
        try:
            from ultralytics import YOLO
            self._model = YOLO(self._model_path)
            self._model.to(self._device)
            self._class_names = list(self._model.names.values())
            logger.info(f"✅ YOLOv11 loaded: {self._model_path} on {self._device}")

            # Initialize ByteTracker via supervision
            try:
                import supervision as sv
                self._tracker = sv.ByteTracker(
                    track_activation_threshold=0.25,
                    lost_track_buffer=30,
                    minimum_matching_threshold=0.8,
                    frame_rate=25,
                )
                logger.info("✅ ByteTracker initialized")
            except Exception as e:
                logger.warning(f"ByteTracker init failed: {e} — tracking disabled")
                self._tracker = None

        except Exception as exc:
            logger.warning(f"YOLOv11 load failed: {exc}. Using mock detector.")
            self._model = None

    def detect(self, frame: np.ndarray) -> list[dict[str, Any]]:
        """
        Detect objects in frame using YOLOv11 + ByteTracker.

        Returns:
            List of detection dicts (serializable for API responses)
        """
        if self._model is None:
            return self._mock_detections(frame)

        try:
            results = self._model(
                frame,
                conf=self._confidence_threshold,
                iou=self._iou_threshold,
                max_det=self._max_detections,
                verbose=False,
            )[0]

            detections = []
            raw_detections = []

            for box in results.boxes:
                class_id = int(box.cls[0])
                class_name = self._class_names[class_id] if class_id < len(self._class_names) else "unknown"
                confidence = float(box.conf[0])
                xyxy = box.xyxy[0].tolist()

                det = Detection(
                    class_name=class_name,
                    confidence=confidence,
                    bbox=xyxy,
                    attributes={
                        "class_id": class_id,
                        "priority": CLASS_PRIORITY.get(class_name, 0),
                        "is_security_threat": class_name in {"weapon", "gun", "knife", "fire", "smoke"},
                    },
                )
                raw_detections.append(det)

            # Apply tracking if available
            if self._tracker and raw_detections:
                try:
                    import supervision as sv
                    import numpy as np

                    sv_dets = sv.Detections(
                        xyxy=np.array([d.bbox for d in raw_detections]),
                        confidence=np.array([d.confidence for d in raw_detections]),
                        class_id=np.array([d.attributes["class_id"] for d in raw_detections]),
                    )
                    tracked = self._tracker.update_with_detections(sv_dets)

                    for i, (xyxy, conf, class_id, track_id) in enumerate(
                        zip(tracked.xyxy, tracked.confidence, tracked.class_id, tracked.tracker_id)
                    ):
                        if i < len(raw_detections):
                            raw_detections[i].track_id = int(track_id)

                except Exception as te:
                    logger.debug(f"Tracking update failed: {te}")

            detections = [d.to_dict() for d in raw_detections]
            self._increment_stats(len(detections))
            return detections

        except Exception as exc:
            logger.error(f"YOLO detection error: {exc}")
            return []

    def _mock_detections(self, frame: np.ndarray) -> list[dict[str, Any]]:
        """Return mock detections when model is unavailable (for testing)."""
        h, w = frame.shape[:2] if frame is not None else (480, 640)
        return [
            Detection(
                class_name="person",
                confidence=0.85,
                bbox=[w * 0.3, h * 0.2, w * 0.5, h * 0.8],
                track_id=1,
            ).to_dict()
        ]

    def get_detection_type(self) -> str:
        return "YOLOv11ObjectDetector"

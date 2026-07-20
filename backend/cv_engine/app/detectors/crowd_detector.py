"""
SecureCity AI — Crowd Density Detector
"""

from __future__ import annotations

from typing import Any

import numpy as np

from app.detectors.base_detector import BaseDetector, Detection

ALERT_LEVELS = {
    "low": (0, 2.0),
    "moderate": (2.0, 5.0),
    "high": (5.0, 10.0),
    "critical": (10.0, float("inf")),
}


class CrowdDensityDetector(BaseDetector):
    """
    Crowd density analyzer based on person detections from YOLO.

    Estimates persons/m² and triggers alerts based on configurable thresholds.
    """

    def __init__(
        self,
        alert_threshold: float = 5.0,       # persons/m² for alert
        critical_threshold: float = 10.0,   # persons/m² for critical
        frame_area_m2: float = 100.0,       # Estimated area covered by frame in m²
    ) -> None:
        super().__init__(confidence_threshold=0.0)
        self._alert_threshold = alert_threshold
        self._critical_threshold = critical_threshold
        self._frame_area_m2 = frame_area_m2

    def detect(self, frame: np.ndarray) -> list[Detection]:
        """Not used directly — use analyze() instead."""
        return []

    def analyze(
        self,
        frame: np.ndarray,
        detections: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """
        Analyze crowd density from a list of person detections.

        Args:
            frame: Input frame (for metadata)
            detections: List of detection dicts from YOLODetector

        Returns:
            dict with count, density, alert_level, bounding boxes
        """
        # Filter person detections
        person_detections = [
            d for d in detections
            if d.get("class_name") == "person" and d.get("confidence", 0) > 0.4
        ]
        count = len(person_detections)

        # Estimate density
        density = count / self._frame_area_m2

        # Determine alert level
        alert_level = self._get_alert_level(density)

        # Compute crowd centroid (if persons detected)
        centroid = None
        if person_detections:
            centers = [d.get("center", [0, 0]) for d in person_detections]
            centroid = [
                float(np.mean([c[0] for c in centers])),
                float(np.mean([c[1] for c in centers])),
            ]

        # Cluster analysis (simple bounding box of all persons)
        crowd_bbox = None
        if person_detections:
            bboxes = [d["bbox"] for d in person_detections]
            crowd_bbox = [
                min(b[0] for b in bboxes),
                min(b[1] for b in bboxes),
                max(b[2] for b in bboxes),
                max(b[3] for b in bboxes),
            ]

        self._increment_stats(count)

        return {
            "count": count,
            "density": round(density, 3),
            "density_unit": "persons/m²",
            "alert_level": alert_level,
            "is_alert": alert_level in ("high", "critical"),
            "centroid": centroid,
            "crowd_bbox": crowd_bbox,
            "thresholds": {
                "alert": self._alert_threshold,
                "critical": self._critical_threshold,
            },
        }

    def _get_alert_level(self, density: float) -> str:
        for level, (low, high) in ALERT_LEVELS.items():
            if low <= density < high:
                return level
        return "critical"

    def get_detection_type(self) -> str:
        return "CrowdDensityDetector"


__all__ = ["CrowdDensityDetector"]

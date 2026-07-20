"""
SecureCity AI — Base Detector Abstract Class
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any

import numpy as np


@dataclass
class Detection:
    """Represents a single object detection result."""
    class_name: str
    confidence: float
    bbox: list[float]           # [x1, y1, x2, y2] in pixel coordinates
    track_id: int | None = None
    attributes: dict[str, Any] = field(default_factory=dict)

    @property
    def width(self) -> float:
        return self.bbox[2] - self.bbox[0]

    @property
    def height(self) -> float:
        return self.bbox[3] - self.bbox[1]

    @property
    def area(self) -> float:
        return self.width * self.height

    @property
    def center(self) -> tuple[float, float]:
        return (
            (self.bbox[0] + self.bbox[2]) / 2,
            (self.bbox[1] + self.bbox[3]) / 2,
        )

    @property
    def aspect_ratio(self) -> float:
        if self.height == 0:
            return 0.0
        return self.width / self.height

    def to_dict(self) -> dict[str, Any]:
        return {
            "class_name": self.class_name,
            "confidence": round(self.confidence, 4),
            "bbox": [round(b, 2) for b in self.bbox],
            "track_id": self.track_id,
            "attributes": self.attributes,
            "center": list(self.center),
            "area": round(self.area, 2),
        }

    def iou(self, other: "Detection") -> float:
        """Calculate Intersection over Union with another detection."""
        x1 = max(self.bbox[0], other.bbox[0])
        y1 = max(self.bbox[1], other.bbox[1])
        x2 = min(self.bbox[2], other.bbox[2])
        y2 = min(self.bbox[3], other.bbox[3])

        intersection = max(0, x2 - x1) * max(0, y2 - y1)
        if intersection == 0:
            return 0.0

        union = self.area + other.area - intersection
        return intersection / union if union > 0 else 0.0


class BaseDetector(ABC):
    """
    Abstract base class for all CV Engine detectors.

    All detectors must implement:
        - detect(frame) -> list[Detection]
        - get_detection_type() -> str
    """

    def __init__(self, confidence_threshold: float = 0.5) -> None:
        self._confidence_threshold = confidence_threshold
        self._frame_count: int = 0
        self._detection_count: int = 0

    @abstractmethod
    def detect(self, frame: np.ndarray) -> list[Detection]:
        """
        Run detection on a single frame.

        Args:
            frame: BGR image array (HxWxC)

        Returns:
            List of Detection objects
        """
        ...

    @abstractmethod
    def get_detection_type(self) -> str:
        """Return a string identifier for this detector type."""
        ...

    def get_stats(self) -> dict[str, Any]:
        """Return detector statistics."""
        return {
            "detector_type": self.get_detection_type(),
            "confidence_threshold": self._confidence_threshold,
            "frames_processed": self._frame_count,
            "total_detections": self._detection_count,
        }

    def _increment_stats(self, n_detections: int) -> None:
        self._frame_count += 1
        self._detection_count += n_detections

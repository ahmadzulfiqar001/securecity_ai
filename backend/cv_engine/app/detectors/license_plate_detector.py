"""
SecureCity AI — License Plate Detector using EasyOCR
"""

from __future__ import annotations

from typing import Any
import numpy as np
from loguru import logger

from app.detectors.base_detector import BaseDetector, Detection


class LicensePlateDetector(BaseDetector):
    """
    Detects license plates and recognizes license plate text using EasyOCR.
    """

    def __init__(self, confidence_threshold: float = 0.5, device: str = "cpu") -> None:
        super().__init__(confidence_threshold)
        self.device = device
        self.reader = None
        self._load_reader()

    def _load_reader(self) -> None:
        """Initialize EasyOCR reader."""
        try:
            import easyocr
            # Load English reader
            gpu_enabled = self.device.lower() in ("cuda", "gpu")
            self.reader = easyocr.Reader(["en"], gpu=gpu_enabled, verbose=False)
            logger.info("✅ EasyOCR license plate reader loaded")
        except Exception as e:
            logger.warning(f"EasyOCR reader loading failed: {e}. OCR will be disabled.")
            self.reader = None

    def detect(self, frame: np.ndarray) -> list[Detection]:
        """
        Processes an image frame to detect license plates.
        For a simulation or COCO model, we look for 'car', 'motorcycle', 'truck'
        and perform OCR on their potential license plate regions.
        """
        # Return empty list if reader is not loaded
        if self.reader is None:
            return []

        # In a real environment, we'd run a license plate detection YOLO model,
        # then run OCR on the cropped plate. Here we mock/simulate it by performing OCR on text regions.
        try:
            detections = []
            # Run OCR on the whole image (simplified or target cropped areas)
            results = self.reader.readtext(frame)
            for bbox, text, confidence in results:
                # Filter for text matching license plate format (e.g., length, alpha-numeric)
                cleaned_text = "".join(e for e in text if e.isalnum()).upper()
                if 4 <= len(cleaned_text) <= 10 and confidence > self._confidence_threshold:
                    # Convert bounding box from EasyOCR format [[x,y],[x,y],[x,y],[x,y]] to [x1,y1,x2,y2]
                    x_coords = [p[0] for p in bbox]
                    y_coords = [p[1] for p in bbox]
                    x1, y1 = min(x_coords), min(y_coords)
                    x2, y2 = max(x_coords), max(y_coords)

                    detections.append(Detection(
                        class_name="license_plate",
                        confidence=float(confidence),
                        bbox=[float(x1), float(y1), float(x2), float(y2)],
                        attributes={"plate_number": cleaned_text}
                    ))
            return detections
        except Exception as e:
            logger.error(f"License plate OCR processing error: {e}")
            return []

    def get_detection_type(self) -> str:
        return "LicensePlateDetector"

"""Tests for app/detectors/weapon_detector.py — no MongoDB/Redis needed."""

from __future__ import annotations

import numpy as np
import pytest

from app.detectors.weapon_detector import WeaponDetector


@pytest.fixture(autouse=True)
def _no_firearm_model(monkeypatch):
    monkeypatch.delenv("WEAPON_MODEL_PATH", raising=False)


def _blank_frame() -> np.ndarray:
    return np.zeros((100, 100, 3), dtype=np.uint8)


def test_bladed_weapon_detected_from_yolo_output():
    detector = WeaponDetector(confidence_threshold=0.4)
    yolo_detections = [
        {"class_name": "knife", "confidence": 0.8, "bbox": [10, 10, 30, 30]},
        {"class_name": "person", "confidence": 0.9, "bbox": [0, 0, 50, 50]},
    ]
    result = detector.analyze(_blank_frame(), yolo_detections)

    assert result["weapon_detected"] is True
    assert result["bladed_blunt_count"] == 1
    assert result["firearm_count"] == 0
    assert result["firearm_model_loaded"] is False
    assert result["weapons"][0]["class_name"] == "knife"


def test_no_weapon_when_no_matching_classes():
    detector = WeaponDetector()
    yolo_detections = [{"class_name": "person", "confidence": 0.9, "bbox": [0, 0, 50, 50]}]
    result = detector.analyze(_blank_frame(), yolo_detections)

    assert result["weapon_detected"] is False
    assert result["weapons"] == []


def test_low_confidence_bladed_weapon_filtered_out():
    detector = WeaponDetector(confidence_threshold=0.5)
    yolo_detections = [{"class_name": "scissors", "confidence": 0.2, "bbox": [0, 0, 10, 10]}]
    result = detector.analyze(_blank_frame(), yolo_detections)

    assert result["weapon_detected"] is False


def test_multiple_bladed_classes_detected():
    detector = WeaponDetector(confidence_threshold=0.4)
    yolo_detections = [
        {"class_name": "knife", "confidence": 0.7, "bbox": [0, 0, 10, 10]},
        {"class_name": "baseball bat", "confidence": 0.6, "bbox": [20, 20, 40, 40]},
        {"class_name": "scissors", "confidence": 0.5, "bbox": [50, 50, 60, 60]},
    ]
    result = detector.analyze(_blank_frame(), yolo_detections)

    assert result["bladed_blunt_count"] == 3


def test_get_status_reports_no_firearm_model():
    detector = WeaponDetector()
    status = detector.get_status()

    assert status["firearm_model_loaded"] is False
    assert "bladed_blunt_detection" in status


def test_detect_stub_returns_empty_list():
    detector = WeaponDetector()
    assert detector.detect(_blank_frame()) == []

"""
Tests for app/detectors/fire_smoke_detector.py's classical (non-ML)
detection path — no MongoDB/Redis/training data needed. Exercises the
HSV+flicker/edge-density heuristics directly against synthetically drawn
OpenCV frames, not real fire photos — a mechanical test of the logic, not
a claim of real-world detection accuracy.
"""

from __future__ import annotations

import cv2
import numpy as np
import pytest

from app.detectors.fire_smoke_detector import FireSmokeDetector


@pytest.fixture(autouse=True)
def _no_custom_model(monkeypatch):
    monkeypatch.delenv("FIRE_MODEL_PATH", raising=False)


def _hsv_bgr(h: int, s: int, v: int) -> tuple[int, int, int]:
    hsv = np.uint8([[[h, s, v]]])
    bgr = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)[0][0]
    return tuple(int(c) for c in bgr)


def _frame_with_rect(size: tuple[int, int], area_ratio: float, color_bgr: tuple[int, int, int]) -> np.ndarray:
    h, w = size
    frame = np.zeros((h, w, 3), dtype=np.uint8)
    side = int((area_ratio * h * w) ** 0.5)
    frame[0:side, 0:side] = color_bgr
    return frame


def test_no_detection_on_blank_frame():
    detector = FireSmokeDetector(confidence_threshold=0.5)
    frame = np.zeros((200, 200, 3), dtype=np.uint8)
    result = detector.analyze(frame, camera_id="cam_blank")

    assert result["detected"] is False
    assert result["detections"] == []


def test_flickering_orange_region_triggers_fire():
    detector = FireSmokeDetector(confidence_threshold=0.5, fire_area_ratio_threshold=0.02)
    color = _hsv_bgr(15, 200, 200)
    camera_id = "cam_fire"

    # Build flicker history: alternate a small and large orange region —
    # fire's brightness/extent varies frame-to-frame; a static object doesn't.
    for area in (0.03, 0.09, 0.03, 0.09):
        frame = _frame_with_rect((200, 200), area, color)
        detector.analyze(frame, camera_id=camera_id)

    frame = _frame_with_rect((200, 200), 0.09, color)
    result = detector.analyze(frame, camera_id=camera_id)

    assert result["detected"] is True
    fire_dets = [d for d in result["detections"] if d["class_name"] == "fire"]
    assert len(fire_dets) == 1
    assert fire_dets[0]["attributes"]["detection_method"] == "classical_hsv_flicker"


def test_static_orange_region_does_not_trigger_fire():
    """A constant-size orange region (no flicker) at a size too small to
    cross the threshold on color alone shouldn't false-positive — this is
    what distinguishes fire from a static red/orange object."""
    detector = FireSmokeDetector(confidence_threshold=0.5, fire_area_ratio_threshold=0.02)
    color = _hsv_bgr(15, 200, 200)
    camera_id = "cam_static"

    result = None
    for _ in range(6):
        frame = _frame_with_rect((200, 200), 0.07, color)
        result = detector.analyze(frame, camera_id=camera_id)

    fire_dets = [d for d in result["detections"] if d["class_name"] == "fire"]
    assert fire_dets == []


def test_smoke_like_region_detected():
    detector = FireSmokeDetector(confidence_threshold=0.3, smoke_area_ratio_threshold=0.05)
    color = _hsv_bgr(0, 20, 150)  # low-saturation grey
    frame = _frame_with_rect((200, 200), 0.3, color)
    result = detector.analyze(frame, camera_id="cam_smoke")

    smoke_dets = [d for d in result["detections"] if d["class_name"] == "smoke"]
    assert len(smoke_dets) == 1
    assert smoke_dets[0]["attributes"]["detection_method"] == "classical_hsv_edge_density"


def test_textured_grey_surface_not_flagged_as_smoke():
    """A checkerboard-patterned grey surface has real internal edges —
    shouldn't read as smoke just because it's low-saturation, unlike a
    genuinely uniform smoke-colored region."""
    detector = FireSmokeDetector(confidence_threshold=0.3, smoke_area_ratio_threshold=0.05)

    size = 200
    cell = 6
    board = np.zeros((size, size), dtype=np.uint8)
    for y in range(0, size, cell):
        for x in range(0, size, cell):
            board[y:y + cell, x:x + cell] = 180 if ((x // cell + y // cell) % 2 == 0) else 100
    frame = cv2.cvtColor(board, cv2.COLOR_GRAY2BGR)

    result = detector.analyze(frame, camera_id="cam_texture")
    smoke_dets = [d for d in result["detections"] if d["class_name"] == "smoke"]
    assert smoke_dets == []


def test_get_status_reports_classical_mode():
    detector = FireSmokeDetector()
    status = detector.get_status()

    assert status["custom_model_loaded"] is False
    assert "classical_detection" in status

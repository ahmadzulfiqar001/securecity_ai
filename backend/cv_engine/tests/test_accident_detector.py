"""
Tests for app/detectors/accident_detector.py — no MongoDB/Redis needed.

Uses a monkeypatched, deterministic clock instead of real time.sleep()
loops so speed/deceleration ratios aren't at the mercy of wall-clock
timing jitter in CI.
"""

from __future__ import annotations

from typing import Any

import pytest

import app.core.track_history as track_history_module
from app.core.track_history import TrackHistoryStore
from app.detectors.accident_detector import RoadAccidentDetector


class _FakeClock:
    def __init__(self, step: float = 0.1) -> None:
        self.t = 0.0
        self.step = step

    def __call__(self) -> float:
        self.t += self.step
        return self.t


@pytest.fixture(autouse=True)
def fake_clock(monkeypatch):
    clock = _FakeClock()
    monkeypatch.setattr(track_history_module.time, "monotonic", clock)
    return clock


def _vehicle(track_id: int, cx: float, cy: float, size: float = 20.0, class_name: str = "car") -> dict[str, Any]:
    bbox = [cx - size / 2, cy - size / 2, cx + size / 2, cy + size / 2]
    return {
        "class_name": class_name,
        "confidence": 0.9,
        "bbox": bbox,
        "center": [cx, cy],
        "track_id": track_id,
    }


def test_sudden_deceleration_then_overlap_flags_accident():
    detector = RoadAccidentDetector(TrackHistoryStore())
    camera_id = "cam1"

    # Vehicle moving steadily...
    for i in range(9):
        detector.analyze(camera_id, [_vehicle(1, i * 30, 100)])
    # ...then stopping abruptly.
    result = None
    for _ in range(3):
        result = detector.analyze(camera_id, [_vehicle(1, 240, 100)])

    # A second vehicle appears overlapping vehicle 1's resting position.
    result = detector.analyze(camera_id, [
        _vehicle(1, 240, 100),
        _vehicle(2, 245, 100),
    ])

    assert result["accident_suspected"] is True
    assert result["severity"] == "high"
    incident_types = {i["type"] for i in result["incidents"]}
    assert "sudden_deceleration" in incident_types
    assert "vehicle_overlap" in incident_types
    assert 1 in result["involved_track_ids"]


def test_deceleration_alone_is_not_accident():
    detector = RoadAccidentDetector(TrackHistoryStore())
    camera_id = "cam2"

    for i in range(9):
        detector.analyze(camera_id, [_vehicle(1, i * 30, 100)])
    result = None
    for _ in range(3):
        result = detector.analyze(camera_id, [_vehicle(1, 240, 100)])

    assert result["accident_suspected"] is False
    assert any(i["type"] == "sudden_deceleration" for i in result["incidents"])
    assert not any(i["type"] == "vehicle_overlap" for i in result["incidents"])


def test_overlap_alone_is_not_accident():
    detector = RoadAccidentDetector(TrackHistoryStore())
    result = detector.analyze("cam3", [
        _vehicle(1, 100, 100),
        _vehicle(2, 105, 100),
    ])

    assert result["accident_suspected"] is False
    assert any(i["type"] == "vehicle_overlap" for i in result["incidents"])
    assert not any(i["type"] == "sudden_deceleration" for i in result["incidents"])


def test_non_vehicle_detections_ignored():
    detector = RoadAccidentDetector(TrackHistoryStore())
    result = detector.analyze("cam4", [
        {"class_name": "person", "confidence": 0.9, "bbox": [0, 0, 10, 10], "track_id": 1, "center": [5, 5]},
    ])

    assert result["accident_suspected"] is False
    assert result["incidents"] == []


def test_get_status_reports_frame_count():
    detector = RoadAccidentDetector(TrackHistoryStore())
    detector.analyze("cam5", [])
    detector.analyze("cam5", [])

    status = detector.get_status()
    assert status["frames_analyzed"] == 2
    assert status["accidents_flagged"] == 0

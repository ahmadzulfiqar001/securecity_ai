"""Tests for app/core/track_history.py — no MongoDB/Redis needed."""

from __future__ import annotations

import time

from app.core.track_history import TrackHistoryStore


def test_update_and_get_history():
    store = TrackHistoryStore()
    store.update("cam1", 1, (0.0, 0.0))
    store.update("cam1", 1, (10.0, 0.0))

    history = store.get_history("cam1", 1)
    assert len(history) == 2
    assert history[0][0] == (0.0, 0.0)
    assert history[1][0] == (10.0, 0.0)


def test_get_history_empty_for_unknown_track():
    store = TrackHistoryStore()
    assert store.get_history("cam1", 999) == []


def test_speed_none_with_insufficient_data():
    store = TrackHistoryStore()
    store.update("cam1", 1, (0.0, 0.0))
    assert store.speed("cam1", 1) is None


def test_speed_computation():
    store = TrackHistoryStore()
    store.update("cam1", 1, (0.0, 0.0))
    time.sleep(0.05)
    store.update("cam1", 1, (10.0, 0.0))

    speed = store.speed("cam1", 1)
    assert speed is not None
    # ~10px over ~0.05s => ~200px/s, generous bounds for timing jitter
    assert 50.0 < speed < 800.0


def test_dwell_time_detects_stationary_track():
    store = TrackHistoryStore()
    for _ in range(4):
        store.update("cam1", 1, (100.0, 100.0))
        time.sleep(0.02)

    dwell = store.dwell_time("cam1", 1, max_radius_px=40.0)
    assert dwell > 0.0


def test_dwell_time_zero_for_moving_track():
    store = TrackHistoryStore()
    for i in range(4):
        store.update("cam1", 1, (i * 200.0, 0.0))
        time.sleep(0.01)

    dwell = store.dwell_time("cam1", 1, max_radius_px=5.0)
    assert dwell == 0.0


def test_dwell_time_zero_with_single_sample():
    store = TrackHistoryStore()
    store.update("cam1", 1, (0.0, 0.0))
    assert store.dwell_time("cam1", 1) == 0.0


def test_ttl_expiry():
    store = TrackHistoryStore(ttl_seconds=0.05)
    store.update("cam1", 1, (0.0, 0.0))
    time.sleep(0.1)
    store.update("cam1", 1, (10.0, 0.0))

    history = store.get_history("cam1", 1)
    # The first (now-expired) sample should be filtered out
    assert len(history) == 1
    assert history[0][0] == (10.0, 0.0)


def test_prune_camera():
    store = TrackHistoryStore()
    store.update("cam1", 1, (0.0, 0.0))
    store.prune_camera("cam1")
    assert store.get_history("cam1", 1) == []


def test_get_stats():
    store = TrackHistoryStore()
    store.update("cam1", 1, (0.0, 0.0))
    store.update("cam1", 2, (0.0, 0.0))
    store.update("cam2", 1, (0.0, 0.0))

    stats = store.get_stats()
    assert stats["cameras_tracked"] == 2
    assert stats["total_tracks"] == 3

"""
SecureCity AI — Track History Store

Keeps a short rolling window of (centroid, timestamp) samples per
ByteTracker `track_id`, scoped per camera. Shared by RoadAccidentDetector
(speed/deceleration) and BehaviorAnalyzer (loitering dwell-time) so both
heuristics reuse the same bookkeeping instead of each maintaining their own.
"""

from __future__ import annotations

import time
from collections import deque
from typing import Any

Sample = tuple[tuple[float, float], float]  # (centroid, timestamp)


class TrackHistoryStore:
    """
    In-memory, per-camera, per-track_id history of recent centroid samples.

    Not persisted — this is a short-lived motion buffer for a single
    running process, not a database. Entries older than `ttl_seconds` are
    dropped lazily on access.

    SCALING BOUNDARY: this state is process-local and not shared across
    workers or replicas. Running cv_engine with more than one uvicorn
    worker (or more than one container instance behind a load balancer)
    would silently split each camera's frames across processes with
    inconsistent track history — accident/behavior detection, which reads
    this store, would see gaps. Keep cv_engine single-worker/single-replica
    until this is moved to a shared store (e.g. Redis); see the Dockerfile
    CMD's `--workers 1`.
    """

    def __init__(self, max_samples: int = 30, ttl_seconds: float = 15.0) -> None:
        self._max_samples = max_samples
        self._ttl_seconds = ttl_seconds
        self._history: dict[str, dict[int, deque[Sample]]] = {}

    def update(self, camera_id: str, track_id: int, centroid: tuple[float, float]) -> None:
        """Record a new centroid sample for a track."""
        camera_tracks = self._history.setdefault(camera_id, {})
        track_samples = camera_tracks.setdefault(track_id, deque(maxlen=self._max_samples))
        track_samples.append((centroid, time.monotonic()))

    def get_history(self, camera_id: str, track_id: int) -> list[Sample]:
        """Return this track's non-expired samples, oldest first."""
        track_samples = self._history.get(camera_id, {}).get(track_id)
        if not track_samples:
            return []
        cutoff = time.monotonic() - self._ttl_seconds
        return [s for s in track_samples if s[1] >= cutoff]

    def dwell_time(self, camera_id: str, track_id: int, max_radius_px: float = 40.0) -> float:
        """
        Seconds this track has stayed within `max_radius_px` of its own
        median position — a proxy for loitering rather than passing through.
        """
        samples = self.get_history(camera_id, track_id)
        if len(samples) < 2:
            return 0.0

        xs = sorted(c[0] for c, _ in samples)
        ys = sorted(c[1] for c, _ in samples)
        median = (xs[len(xs) // 2], ys[len(ys) // 2])

        contained = [
            (centroid, ts) for centroid, ts in samples
            if ((centroid[0] - median[0]) ** 2 + (centroid[1] - median[1]) ** 2) ** 0.5 <= max_radius_px
        ]
        if len(contained) < 2:
            return 0.0
        return contained[-1][1] - contained[0][1]

    def speed(self, camera_id: str, track_id: int, window: int = 5) -> float | None:
        """Approximate pixels/second over the last `window` samples, or None if insufficient data."""
        samples = self.get_history(camera_id, track_id)[-window:]
        if len(samples) < 2:
            return None
        (x1, y1), t1 = samples[0]
        (x2, y2), t2 = samples[-1]
        dt = t2 - t1
        if dt <= 0:
            return None
        distance = ((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5
        return distance / dt

    def prune_camera(self, camera_id: str) -> None:
        """Drop all history for a camera (e.g. when its stream stops)."""
        self._history.pop(camera_id, None)

    def get_stats(self) -> dict[str, Any]:
        return {
            "cameras_tracked": len(self._history),
            "total_tracks": sum(len(tracks) for tracks in self._history.values()),
        }

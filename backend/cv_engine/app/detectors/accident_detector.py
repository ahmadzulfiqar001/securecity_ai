"""
SecureCity AI — Road Accident Detector

Heuristic, not a trained model — same spirit as BehaviorAnalyzer's
fight/person-down checks. No annotated accident-video dataset exists to
train on, but vehicle collisions have a real, well-known motion signature
that doesn't need one: a sharp deceleration and/or two vehicle bounding
boxes suddenly overlapping. Requiring BOTH signals together (rather than
either alone) keeps this conservative — a lone speed drop is often just a
red light, and a lone overlap is often just adjacent lanes from this
camera's angle.

Reuses the same TrackHistoryStore that BehaviorAnalyzer's loitering check
uses, keyed by the ByteTracker `track_id` YOLODetector already produces.
"""

from __future__ import annotations

from typing import Any

from app.core.track_history import TrackHistoryStore

VEHICLE_CLASSES = {"car", "truck", "motorcycle", "bus"}

# A vehicle must have been moving at least this fast (px/s) before a speed
# drop counts as a "sudden stop" — otherwise a parked car reads as one.
MIN_MOVING_SPEED_PX_S = 15.0
SUDDEN_STOP_RATIO = 0.35  # current speed <= 35% of its own recent peak speed
COLLISION_IOU_THRESHOLD = 0.15


class RoadAccidentDetector:
    """Flags likely road accidents from vehicle track motion + overlap patterns."""

    def __init__(self, track_history: TrackHistoryStore) -> None:
        self._track_history = track_history
        self._frame_count = 0
        self._accident_count = 0

    def analyze(
        self,
        camera_id: str,
        detections: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """
        Args:
            camera_id: identifies which camera's track history to use.
            detections: YOLO detections for this frame (any classes — this
                filters to vehicles internally), each with a `track_id`.

        Returns:
            dict with accident_suspected, severity, incidents (reasoning
            per flagged vehicle/pair), involved_track_ids.
        """
        vehicles = [
            d for d in detections
            if d.get("class_name") in VEHICLE_CLASSES and d.get("track_id") is not None
        ]

        for v in vehicles:
            center = v.get("center") or self._bbox_center(v["bbox"])
            self._track_history.update(camera_id, v["track_id"], tuple(center))

        incidents: list[dict[str, Any]] = []
        involved: set[int] = set()

        for v in vehicles:
            track_id = v["track_id"]
            speed_now = self._track_history.speed(camera_id, track_id, window=3)
            speed_recent = self._track_history.speed(camera_id, track_id, window=10)
            if speed_now is None or speed_recent is None:
                continue
            if speed_recent >= MIN_MOVING_SPEED_PX_S and speed_now <= speed_recent * SUDDEN_STOP_RATIO:
                incidents.append({
                    "type": "sudden_deceleration",
                    "track_id": track_id,
                    "reasoning": f"Vehicle track {track_id} dropped from ~{speed_recent:.1f}px/s to ~{speed_now:.1f}px/s",
                })
                involved.add(track_id)

        for i in range(len(vehicles)):
            for j in range(i + 1, len(vehicles)):
                iou = self._bbox_iou(vehicles[i]["bbox"], vehicles[j]["bbox"])
                if iou >= COLLISION_IOU_THRESHOLD:
                    id_i, id_j = vehicles[i]["track_id"], vehicles[j]["track_id"]
                    incidents.append({
                        "type": "vehicle_overlap",
                        "track_ids": [id_i, id_j],
                        "iou": round(iou, 3),
                        "reasoning": f"Vehicle tracks {id_i} and {id_j} bounding boxes overlap (IoU={iou:.2f})",
                    })
                    involved.update([id_i, id_j])

        has_deceleration = any(i["type"] == "sudden_deceleration" for i in incidents)
        has_overlap = any(i["type"] == "vehicle_overlap" for i in incidents)
        accident_suspected = has_deceleration and has_overlap

        self._frame_count += 1
        if accident_suspected:
            self._accident_count += 1

        severity = "high" if accident_suspected else ("low" if incidents else "none")

        return {
            "accident_suspected": accident_suspected,
            "severity": severity,
            "incidents": incidents,
            "involved_track_ids": sorted(involved),
        }

    def _bbox_center(self, bbox: list[float]) -> tuple[float, float]:
        return ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2)

    def _bbox_iou(self, a: list[float], b: list[float]) -> float:
        x1 = max(a[0], b[0])
        y1 = max(a[1], b[1])
        x2 = min(a[2], b[2])
        y2 = min(a[3], b[3])
        intersection = max(0.0, x2 - x1) * max(0.0, y2 - y1)
        if intersection == 0:
            return 0.0
        area_a = (a[2] - a[0]) * (a[3] - a[1])
        area_b = (b[2] - b[0]) * (b[3] - b[1])
        union = area_a + area_b - intersection
        return intersection / union if union > 0 else 0.0

    def get_detection_type(self) -> str:
        return "RoadAccidentDetector"

    def get_status(self) -> dict[str, Any]:
        return {
            "detection_method": "track_history_motion_heuristic (deceleration + overlap), no training data required",
            "frames_analyzed": self._frame_count,
            "accidents_flagged": self._accident_count,
        }

"""
SecureCity AI — Behavior Analyzer
"""

from __future__ import annotations

from typing import Any
import numpy as np

from app.core.track_history import TrackHistoryStore

# A person's track must stay within a small radius for at least this long
# to count as loitering rather than someone briefly pausing while passing through.
LOITERING_SECONDS = 20.0
LOITERING_RADIUS_PX = 40.0


class BehaviorAnalyzer:
    """
    Analyzes detected entities and bounding boxes to infer anomalous behaviors:
    - Potential physical altercation (close overlaps between people)
    - Medical emergency (person lying down - aspect ratio check)
    - Suspicious loitering (track dwell-time, via TrackHistoryStore)
    - Crowd gathering

    Weapon detection is NOT duplicated here — it's owned by
    app/detectors/weapon_detector.py; pass its result via `weapon_result`
    so a weapon only gets classified once instead of by two detectors
    disagreeing with each other.
    """

    def __init__(self, track_history: TrackHistoryStore | None = None) -> None:
        self._track_history = track_history or TrackHistoryStore()
        self._frame_count = 0
        self._alert_count = 0

    def get_status(self) -> dict[str, Any]:
        return {
            "detection_method": "bbox_overlap_and_aspect_ratio_heuristics",
            "loitering_threshold_seconds": LOITERING_SECONDS,
            "frames_analyzed": self._frame_count,
            "alerts_triggered": self._alert_count,
        }

    def analyze(
        self,
        frame: np.ndarray,
        detections: list[dict[str, Any]],
        camera_id: str = "default",
        weapon_result: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """
        Analyze detections in the current frame to identify anomalous behaviors.

        Args:
            frame: Raw OpenCV frame image
            detections: List of detection dictionaries from YOLO
            camera_id: scopes the loitering track-history buffer
            weapon_result: WeaponDetector.analyze()'s output, if available —
                reused here instead of re-detecting weapons independently

        Returns:
            dict containing detected actions, alert status, and reasoning
        """
        actions = []
        alert_triggered = False
        details = {}

        # 1. Weapon check — delegates to WeaponDetector's result
        if weapon_result and weapon_result.get("weapon_detected"):
            actions.append("weapon_detected")
            alert_triggered = True
            details["weapon_details"] = weapon_result.get("weapons", [])

        # 2. Altercation / Crowd Fight Check (bounding box overlap between persons)
        persons = [d for d in detections if d.get("class_name") == "person"]
        overlaps = 0
        if len(persons) >= 2:
            for i in range(len(persons)):
                for j in range(i + 1, len(persons)):
                    if self._check_bbox_overlap(persons[i]["bbox"], persons[j]["bbox"]):
                        overlaps += 1

        if overlaps >= 3:
            actions.append("potential_fight")
            alert_triggered = True
            details["fight_probability"] = 0.8
            details["overlapping_persons_count"] = overlaps
        elif overlaps >= 1:
            actions.append("close_physical_contact")
            details["overlapping_persons_count"] = overlaps

        # 3. Medical Emergency / Fallen Person check (aspect ratio)
        fallen_persons = []
        for p in persons:
            bbox = p["bbox"]  # [x1, y1, x2, y2]
            w = bbox[2] - bbox[0]
            h = bbox[3] - bbox[1]
            # If a person is significantly wider than they are tall, they are horizontal
            if h > 0 and (w / h) > 1.5:
                fallen_persons.append(p)

        if fallen_persons:
            actions.append("person_down")
            alert_triggered = True
            details["fallen_person_details"] = [
                {"bbox": fp["bbox"], "confidence": round(fp["confidence"], 2)} for fp in fallen_persons
            ]

        # 4. Crowd gathering
        if len(persons) > 8:
            actions.append("crowd_gathering")
            details["crowd_size"] = len(persons)

        # 5. Loitering — a tracked person who has stayed within a small
        # radius for a while, rather than passing through
        loiterers = []
        for p in persons:
            track_id = p.get("track_id")
            if track_id is None:
                continue
            center = p.get("center") or self._bbox_center(p["bbox"])
            self._track_history.update(camera_id, track_id, tuple(center))
            dwell = self._track_history.dwell_time(camera_id, track_id, max_radius_px=LOITERING_RADIUS_PX)
            if dwell >= LOITERING_SECONDS:
                loiterers.append({"track_id": track_id, "dwell_seconds": round(dwell, 1)})

        if loiterers:
            actions.append("loitering")
            details["loitering_details"] = loiterers

        self._frame_count += 1
        if alert_triggered:
            self._alert_count += 1

        return {
            "actions": actions,
            "alert_triggered": alert_triggered,
            "details": details,
            "alert_level": "high" if alert_triggered else "low"
        }

    def _bbox_center(self, bbox: list[float]) -> tuple[float, float]:
        return ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2)

    def _check_bbox_overlap(self, boxA: list[float], boxB: list[float]) -> bool:
        """Check if two bounding boxes overlap significantly."""
        xA = max(boxA[0], boxB[0])
        yA = max(boxA[1], boxB[1])
        xB = min(boxA[2], boxB[2])
        yB = min(boxA[3], boxB[3])

        # Intersection area
        inter_width = max(0.0, xB - xA)
        inter_height = max(0.0, yB - yA)
        inter_area = inter_width * inter_height

        if inter_area <= 0:
            return False

        # Area of both boxes
        areaA = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1])
        areaB = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1])

        # Overlap ratio relative to the smaller box
        min_area = min(areaA, areaB)
        if min_area <= 0:
            return False

        overlap_ratio = inter_area / min_area
        return overlap_ratio > 0.4

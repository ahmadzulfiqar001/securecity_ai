"""
SecureCity AI — Shared Frame Analysis Orchestration

Runs the full detector suite (YOLO object detection + weapon + crowd +
fire/smoke + suspicious behavior + road accident) on a single frame.

Extracted out of what used to be inline logic in `/analyze/image` so that
`StreamProcessor` can call the exact same pipeline — previously live RTSP
streams only ran bare YOLO object detection and never got crowd/fire/
weapon/behavior/accident analysis, even though that's the actual
real-time use case.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np

from app.detectors.accident_detector import RoadAccidentDetector
from app.detectors.behavior_detector import BehaviorAnalyzer
from app.detectors.crowd_detector import CrowdDensityDetector
from app.detectors.fire_smoke_detector import FireSmokeDetector
from app.detectors.weapon_detector import WeaponDetector
from app.detectors.yolo_detector import YOLODetector


@dataclass
class DetectorSuite:
    """Bundles the detector instances run_full_analysis() needs."""
    yolo: YOLODetector
    crowd: CrowdDensityDetector
    fire_smoke: FireSmokeDetector
    weapon: WeaponDetector
    behavior: BehaviorAnalyzer
    accident: RoadAccidentDetector


def run_full_analysis(
    frame: np.ndarray,
    camera_id: str,
    detectors: DetectorSuite,
    run_all_detectors: bool = True,
) -> dict[str, Any]:
    """
    Run the full detector suite on one frame.

    Returns a dict shaped for the `AnalysisResult` schema: detections,
    crowd_analysis, fire_smoke_analysis, weapon_analysis, behavior_analysis,
    accident_analysis.
    """
    yolo_detections = detectors.yolo.detect(frame)

    result: dict[str, Any] = {
        "detections": yolo_detections,
        "crowd_analysis": None,
        "fire_smoke_analysis": None,
        "weapon_analysis": None,
        "behavior_analysis": None,
        "accident_analysis": None,
    }

    if not run_all_detectors:
        return result

    result["crowd_analysis"] = detectors.crowd.analyze(frame, yolo_detections)
    result["fire_smoke_analysis"] = detectors.fire_smoke.analyze(frame, camera_id=camera_id)
    result["weapon_analysis"] = detectors.weapon.analyze(frame, yolo_detections)
    result["behavior_analysis"] = detectors.behavior.analyze(
        frame, yolo_detections, camera_id=camera_id, weapon_result=result["weapon_analysis"],
    )
    result["accident_analysis"] = detectors.accident.analyze(camera_id, yolo_detections)

    return result


def has_security_relevant_finding(analysis: dict[str, Any]) -> bool:
    """
    True if any detector flagged something worth durably logging — mirrors
    the same "only log when something's actually there" reasoning
    `/analyze/image` already used, now generalized across all detectors
    instead of just the raw YOLO `is_security_threat` attribute + fire.
    """
    weapon = analysis.get("weapon_analysis") or {}
    if weapon.get("weapon_detected"):
        return True

    fire_smoke = analysis.get("fire_smoke_analysis") or {}
    if fire_smoke.get("detected"):
        return True

    behavior = analysis.get("behavior_analysis") or {}
    if behavior.get("alert_triggered"):
        return True

    accident = analysis.get("accident_analysis") or {}
    if accident.get("accident_suspected"):
        return True

    crowd = analysis.get("crowd_analysis") or {}
    if crowd.get("is_alert"):
        return True

    return False


def threat_classes_for(analysis: dict[str, Any]) -> list[str]:
    """Flatten a short list of threat labels for MongoDB logging/filtering."""
    classes: list[str] = []
    weapon = analysis.get("weapon_analysis") or {}
    if weapon.get("weapon_detected"):
        classes.extend(w["class_name"] for w in weapon.get("weapons", []))

    fire_smoke = analysis.get("fire_smoke_analysis") or {}
    if fire_smoke.get("detected"):
        classes.extend(d["class_name"] for d in fire_smoke.get("detections", []))

    behavior = analysis.get("behavior_analysis") or {}
    classes.extend(behavior.get("actions", []))

    accident = analysis.get("accident_analysis") or {}
    if accident.get("accident_suspected"):
        classes.append("road_accident")

    return sorted(set(classes))

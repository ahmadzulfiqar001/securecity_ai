"""
SecureCity AI — EmergencySeverityScorer
Heuristic urgency scoring for incoming SOS alerts (Emergency Queue triage).

Distinct from CrimePredictor.classify_severity(), which scores a citizen's
*incident report* (a robbery, a fire, etc.). This scores an active *SOS
alert* (sos_events) so authorities can prioritize which one to respond to
first — different inputs, different consumer (the Emergency Queue
dashboard), different question ("how urgently does THIS alert need a
human right now" vs. "how bad was the reported incident").

No synthetic bootstrap training, unlike TrafficPredictor. Traffic
congestion has real, simulatable environmental patterns (rush hour, etc.)
worth learning from bootstrap data. Emergency urgency's real ground truth
would be an authority's actual triage judgment on a real alert — that
doesn't exist to simulate; generating synthetic labels here would just
mean training a model to imitate this same hand-written formula, which
adds nothing over running the formula directly. `train()` is reserved for
real authority-labeled outcomes once the Emergency Queue has been in use
long enough to produce them.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

import pandas as pd

CRITICAL_KEYWORDS = [
    "gun", "weapon", "knife", "blood", "unconscious", "dead",
    "can't breathe", "cant breathe", "explosion", "fire", "drowning",
    "stabbed", "shot",
]

PRIORITY_THRESHOLDS = {
    "LOW": (0, 40),
    "MEDIUM": (40, 60),
    "HIGH": (60, 80),
    "CRITICAL": (80, 101),
}


class EmergencySeverityScorer:
    """
    Rule-based urgency scorer for `sos_events`, producing a [0, 100]
    urgency score and a priority level for Emergency Queue triage.
    """

    def __init__(self) -> None:
        self._is_trained: bool = False
        self._trained_at: datetime | None = None

    @property
    def is_trained(self) -> bool:
        return self._is_trained

    def score(
        self,
        seconds_since_triggered: float,
        area_safety_score: float = 50.0,
        hour: int = 12,
        repeat_trigger_count_24h: int = 0,
        message: str | None = None,
        user_is_moving: bool = False,
    ) -> dict[str, Any]:
        """
        Score an active SOS alert's urgency.

        Args:
            seconds_since_triggered: how long the alert has gone unacknowledged.
            area_safety_score: the area's SafetyScorer score [0, 100] (lower = riskier).
            hour: hour of day the alert was triggered (0-23).
            repeat_trigger_count_24h: how many times this user has triggered
                an SOS in the last 24 hours (an escalating pattern).
            message: optional free-text message attached to the alert.
            user_is_moving: whether the user's location is actively changing.

        Returns:
            dict with urgency_score [0, 100], priority_level, reasoning,
            model_trained.
        """
        score = 40.0  # baseline urgency for any SOS trigger
        reasons: list[str] = []

        if seconds_since_triggered > 300:
            score += 20
            reasons.append("unacknowledged for over 5 minutes")
        elif seconds_since_triggered > 120:
            score += 10
            reasons.append("unacknowledged for over 2 minutes")

        if area_safety_score < 30:
            score += 20
            reasons.append("triggered in a high-risk area")
        elif area_safety_score < 50:
            score += 10
            reasons.append("triggered in a moderate-risk area")

        if hour >= 22 or hour <= 5:
            score += 10
            reasons.append("nighttime incident")

        if repeat_trigger_count_24h >= 2:
            score += 15
            reasons.append(f"user has triggered SOS {repeat_trigger_count_24h} times in the last 24h")

        if message:
            matched = [kw for kw in CRITICAL_KEYWORDS if kw in message.lower()]
            if matched:
                score += 25
                reasons.append(f"message contains critical keyword(s): {', '.join(matched)}")

        if user_is_moving:
            score += 5
            reasons.append("user location is actively changing")

        score = min(100.0, score)
        priority_level = self._get_priority_level(score)

        if not reasons:
            reasons.append("standard SOS trigger — no elevated risk factors detected")

        return {
            "urgency_score": round(score, 1),
            "priority_level": priority_level,
            "reasoning": "; ".join(reasons).capitalize() + ".",
            "model_trained": self._is_trained,
        }

    def _get_priority_level(self, score: float) -> str:
        for level, (low, high) in PRIORITY_THRESHOLDS.items():
            if low <= score < high:
                return level
        return "CRITICAL"

    def train(self, df: pd.DataFrame) -> dict[str, float]:
        """
        Reserved for real authority-labeled SOS outcome data (an
        `actual_priority` column reflecting what authorities actually did)
        once the Emergency Queue has produced enough of it. Not called by
        any retraining task in this pass — see the module docstring for
        why a synthetic bootstrap isn't used here.
        """
        raise NotImplementedError(
            "EmergencySeverityScorer.train() requires real authority-labeled "
            "SOS outcome data, which doesn't exist yet. score() is the "
            "production path until then."
        )

    def get_status(self) -> dict[str, Any]:
        return {
            "model_type": "HeuristicScorer (rule-based, not yet ML-trained)",
            "is_trained": self._is_trained,
            "trained_at": self._trained_at.isoformat() if self._trained_at else None,
            "note": "train() is reserved for real authority-labeled SOS outcomes; none exist yet.",
        }

"""
Tests for app/models/emergency_severity_scorer.py — a heuristic (not yet
ML-trained) urgency scorer for SOS alert triage. Pure unit tests — no
MongoDB/Redis required.
"""

from __future__ import annotations

import pytest

from app.models.emergency_severity_scorer import EmergencySeverityScorer


def test_baseline_sos_is_at_least_low_priority():
    scorer = EmergencySeverityScorer()
    result = scorer.score(seconds_since_triggered=10, area_safety_score=80, hour=14)

    assert 0.0 <= result["urgency_score"] <= 100.0
    assert result["priority_level"] in ("LOW", "MEDIUM", "HIGH", "CRITICAL")
    assert result["model_trained"] is False
    assert "reasoning" in result and len(result["reasoning"]) > 0


def test_critical_keyword_and_repeat_triggers_escalate_priority():
    scorer = EmergencySeverityScorer()

    calm = scorer.score(
        seconds_since_triggered=30,
        area_safety_score=80,
        hour=14,
        repeat_trigger_count_24h=0,
        message=None,
    )
    severe = scorer.score(
        seconds_since_triggered=400,
        area_safety_score=20,
        hour=2,
        repeat_trigger_count_24h=3,
        message="there is a gun, someone is unconscious",
        user_is_moving=True,
    )

    assert severe["urgency_score"] > calm["urgency_score"]
    priority_order = {"LOW": 0, "MEDIUM": 1, "HIGH": 2, "CRITICAL": 3}
    assert priority_order[severe["priority_level"]] > priority_order[calm["priority_level"]]
    assert severe["priority_level"] == "CRITICAL"


def test_score_capped_at_100():
    scorer = EmergencySeverityScorer()
    result = scorer.score(
        seconds_since_triggered=1000,
        area_safety_score=0,
        hour=3,
        repeat_trigger_count_24h=10,
        message="gun weapon knife blood unconscious dead explosion",
        user_is_moving=True,
    )
    assert result["urgency_score"] == 100.0
    assert result["priority_level"] == "CRITICAL"


def test_get_status_reports_untrained():
    scorer = EmergencySeverityScorer()
    status = scorer.get_status()
    assert status["is_trained"] is False
    assert status["trained_at"] is None


def test_train_is_not_implemented_yet():
    scorer = EmergencySeverityScorer()
    with pytest.raises(NotImplementedError):
        scorer.train(df=None)

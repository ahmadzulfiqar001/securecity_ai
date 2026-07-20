"""
Tests for app/models/traffic_predictor.py and its synthetic bootstrap
dataset. Pure model/unit tests — no MongoDB/Redis required.
"""

from __future__ import annotations

from app.data.synthetic_traffic_dataset import ZONES, generate_synthetic_traffic_dataset
from app.models.traffic_predictor import TrafficPredictor


def test_dataset_shape():
    df = generate_synthetic_traffic_dataset(n_samples=500, seed=42)
    assert len(df) == 500
    expected_columns = {
        "hour", "day_of_week", "month", "zone_id", "weather_code",
        "base_speed_kmh", "nearby_incidents_24h", "event_nearby",
        "congestion_index", "delay_minutes",
    }
    assert expected_columns.issubset(set(df.columns))
    assert df["congestion_index"].between(0.0, 1.0).all()
    assert set(df["zone_id"].unique()).issubset(set(ZONES))


def test_dataset_reflects_rush_hour_pattern():
    """Rush-hour congestion should be meaningfully higher than 3am congestion."""
    df = generate_synthetic_traffic_dataset(n_samples=20000, seed=42)
    weekday = df[df["day_of_week"] < 5]

    rush_hour = weekday[weekday["hour"].isin([8, 18])]
    late_night = weekday[weekday["hour"] == 3]

    assert rush_hour["congestion_index"].mean() > late_night["congestion_index"].mean() + 0.2


def test_untrained_predict_fallback():
    predictor = TrafficPredictor()
    result = predictor.predict(hour=8, day_of_week=1, month=6, zone_id="zone_a")

    assert result["model_trained"] is False
    assert result["congestion_level"] == "LOW"
    assert 0.0 <= result["congestion_index"] <= 1.0


def test_train_and_predict():
    df = generate_synthetic_traffic_dataset(n_samples=3000, seed=42)
    predictor = TrafficPredictor()
    metrics = predictor.train(df)

    assert predictor.is_trained is True
    assert metrics["r2"] > 0.5  # should beat a naive baseline comfortably
    assert metrics["mae"] >= 0.0
    assert metrics["training_samples"] + metrics["test_samples"] == len(df)

    result = predictor.predict(
        hour=8, day_of_week=1, month=6, zone_id="zone_a",
        nearby_incidents_24h=2, event_nearby=False,
    )
    assert result["model_trained"] is True
    assert result["congestion_level"] in ("LOW", "MODERATE", "HEAVY", "SEVERE")
    assert result["estimated_delay_minutes"] >= 0.0
    assert len(result["top_features"]) > 0


def test_get_status_untrained():
    predictor = TrafficPredictor()
    status = predictor.get_status()
    assert status["is_trained"] is False
    assert status["trained_at"] is None
    assert status["model_type"] == "XGBoostRegressor"

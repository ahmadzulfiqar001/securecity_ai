"""
app/data/synthetic_traffic_dataset.py
======================================
Synthetic bootstrap training data for TrafficPredictor.

`traffic_data` has no writer anywhere in the system yet (no camera-based
vehicle counting, no sensor feed) — there is no real dataset to train on.
This generator encodes known, real-world domain patterns (rush-hour
congestion, weekend/weekday differences, nighttime light traffic, weather
and incident effects) as the features, and the model then has to learn to
recover those patterns from noisy samples — a legitimate bootstrap, not
fabricated ground truth for its own sake. Swap this out for a real
`traffic_data` query the moment sensor/reporting data actually exists.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

ZONES = [f"zone_{c}" for c in "abcdefgh"]


def generate_synthetic_traffic_dataset(n_samples: int = 5000, seed: int = 42) -> pd.DataFrame:
    """
    Generate a synthetic traffic congestion dataset.

    Columns:
        hour, day_of_week, month, zone_id, weather_code, base_speed_kmh,
        nearby_incidents_24h, event_nearby, congestion_index (target, 0-1),
        delay_minutes (target)
    """
    rng = np.random.default_rng(seed)

    hour = rng.integers(0, 24, size=n_samples)
    day_of_week = rng.integers(0, 7, size=n_samples)
    month = rng.integers(1, 13, size=n_samples)
    zone_id = rng.choice(ZONES, size=n_samples)
    weather_code = rng.integers(0, 5, size=n_samples)  # 0=clear ... 4=fog
    base_speed_kmh = rng.uniform(30.0, 80.0, size=n_samples)
    nearby_incidents_24h = rng.poisson(0.5, size=n_samples)
    event_nearby = rng.random(size=n_samples) < 0.05

    is_weekend = day_of_week >= 5
    is_rush_hour = np.isin(hour, [7, 8, 9, 17, 18, 19]) & ~is_weekend
    is_night = (hour >= 22) | (hour <= 5)

    congestion = np.full(n_samples, 0.15)
    congestion += np.where(is_rush_hour, 0.55, 0.0)
    congestion += np.where(~is_rush_hour & is_weekend, 0.15, 0.0)
    congestion += np.where(~is_rush_hour & ~is_weekend & ~is_night, 0.25, 0.0)
    congestion -= np.where(is_night, 0.10, 0.0)
    congestion += weather_code * 0.05
    congestion += np.minimum(nearby_incidents_24h * 0.08, 0.3)
    congestion += np.where(event_nearby, 0.2, 0.0)
    congestion += rng.normal(0, 0.05, size=n_samples)
    congestion = np.clip(congestion, 0.0, 1.0)

    # Rough delay proxy: more congestion + slower base road = longer delay.
    delay_minutes = congestion * 25.0 * (60.0 / base_speed_kmh)

    return pd.DataFrame({
        "hour": hour,
        "day_of_week": day_of_week,
        "month": month,
        "zone_id": zone_id,
        "weather_code": weather_code,
        "base_speed_kmh": base_speed_kmh,
        "nearby_incidents_24h": nearby_incidents_24h,
        "event_nearby": event_nearby.astype(int),
        "congestion_index": congestion,
        "delay_minutes": delay_minutes,
    })

"""
SecureCity AI — TrafficPredictor Model
XGBoost-based traffic congestion regression with SHAP explainability.

Mirrors app/models/crime_predictor.py's structure (same engineered
features, SHAP explainability, save/load, train/evaluate) — the problem
shape differs (regression, not classification), so the model type and
evaluation metrics differ accordingly.
"""

from __future__ import annotations

import os
from datetime import datetime
from typing import Any

import joblib
import numpy as np
import pandas as pd
import shap
from loguru import logger
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBRegressor

CONGESTION_THRESHOLDS = {
    "LOW": (0.0, 0.35),
    "MODERATE": (0.35, 0.60),
    "HEAVY": (0.60, 0.80),
    "SEVERE": (0.80, 1.01),
}

FEATURE_NAMES = [
    "hour",
    "day_of_week",
    "month",
    "zone_id_encoded",
    "weather_code",
    "base_speed_kmh",
    "nearby_incidents_24h",
    "event_nearby",
    # Engineered features
    "is_night",
    "is_weekend",
    "is_rush_hour",
    "hour_sin",
    "hour_cos",
    "day_sin",
    "day_cos",
]


class TrafficPredictor:
    """
    XGBoost regressor predicting a [0, 1] traffic congestion index, with
    calibrated-by-construction outputs (regression, not probability
    calibration) and SHAP-based explainability.

    Features:
        - hour (0-23), day_of_week (0=Mon), month (1-12)
        - zone_id (categorical, encoded)
        - weather_code (0=clear ... 4=fog)
        - base_speed_kmh (free-flow speed for the road/zone)
        - nearby_incidents_24h (accidents/incidents nearby — raise congestion)
        - event_nearby (bool — large gathering/event flag)

    Output:
        - congestion_index: float [0, 1]
        - congestion_level: str (LOW/MODERATE/HEAVY/SEVERE)
        - estimated_delay_minutes: float (derived from congestion_index and base_speed_kmh)
        - top_features: SHAP feature importances
    """

    def __init__(self) -> None:
        self._model: XGBRegressor | None = None
        self._zone_encoder = LabelEncoder()
        self._explainer: shap.TreeExplainer | None = None
        self._is_trained: bool = False
        self._trained_at: datetime | None = None
        self._training_metrics: dict[str, float] = {}

        self._base_regressor_params = dict(
            n_estimators=300,
            max_depth=6,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            min_child_weight=3,
            reg_alpha=0.1,
            reg_lambda=1.0,
            random_state=42,
            n_jobs=-1,
            tree_method="hist",
        )

    @property
    def is_trained(self) -> bool:
        return self._is_trained

    def _engineer_features(self, features: dict[str, Any]) -> np.ndarray:
        """Engineer temporal and interaction features from raw inputs."""
        hour = features["hour"]
        day_of_week = features["day_of_week"]

        hour_sin = np.sin(2 * np.pi * hour / 24)
        hour_cos = np.cos(2 * np.pi * hour / 24)
        day_sin = np.sin(2 * np.pi * day_of_week / 7)
        day_cos = np.cos(2 * np.pi * day_of_week / 7)

        is_night = 1 if (hour >= 22 or hour <= 5) else 0
        is_weekend = 1 if day_of_week >= 5 else 0
        is_rush_hour = 1 if (not is_weekend and (7 <= hour <= 9 or 17 <= hour <= 19)) else 0

        zone_id = features.get("zone_id", "unknown")
        try:
            zone_id_encoded = self._zone_encoder.transform([zone_id])[0]
        except (ValueError, AttributeError):
            zone_id_encoded = 0

        return np.array([
            hour,
            day_of_week,
            features.get("month", 1),
            zone_id_encoded,
            features.get("weather_code", 0),
            features.get("base_speed_kmh", 50.0),
            features.get("nearby_incidents_24h", 0),
            int(features.get("event_nearby", False)),
            is_night,
            is_weekend,
            is_rush_hour,
            hour_sin,
            hour_cos,
            day_sin,
            day_cos,
        ], dtype=np.float32)

    def predict(
        self,
        hour: int,
        day_of_week: int,
        month: int,
        zone_id: str,
        weather_code: int = 0,
        base_speed_kmh: float = 50.0,
        nearby_incidents_24h: int = 0,
        event_nearby: bool = False,
    ) -> dict[str, Any]:
        """
        Predict traffic congestion for given spatiotemporal features.

        Returns:
            dict containing congestion_index, congestion_level,
            estimated_delay_minutes, top_features, model_trained,
            prediction_time_ms.
        """
        if not self._is_trained or self._model is None:
            # Neutral fallback for an untrained model — same shape/intent
            # as CrimePredictor.predict()'s untrained fallback.
            return {
                "congestion_index": 0.3,
                "congestion_level": "LOW",
                "estimated_delay_minutes": 0.0,
                "top_features": [],
                "model_trained": False,
                "prediction_time_ms": 0.0,
            }

        import time
        start = time.monotonic()

        features = {
            "hour": hour,
            "day_of_week": day_of_week,
            "month": month,
            "zone_id": zone_id,
            "weather_code": weather_code,
            "base_speed_kmh": base_speed_kmh,
            "nearby_incidents_24h": nearby_incidents_24h,
            "event_nearby": event_nearby,
        }

        feature_vector = self._engineer_features(features).reshape(1, -1)

        congestion_index = float(np.clip(self._model.predict(feature_vector)[0], 0.0, 1.0))
        congestion_level = self._get_congestion_level(congestion_index)

        # Same derivation the synthetic dataset uses to define its target,
        # applied here to turn the predicted index into a minutes estimate.
        estimated_delay_minutes = congestion_index * 25.0 * (60.0 / max(base_speed_kmh, 1.0))

        top_features = self._compute_shap_features(feature_vector)

        elapsed_ms = (time.monotonic() - start) * 1000

        return {
            "congestion_index": round(congestion_index, 4),
            "congestion_level": congestion_level,
            "estimated_delay_minutes": round(estimated_delay_minutes, 1),
            "top_features": top_features,
            "model_trained": True,
            "prediction_time_ms": round(elapsed_ms, 2),
        }

    def _get_congestion_level(self, congestion_index: float) -> str:
        for level, (low, high) in CONGESTION_THRESHOLDS.items():
            if low <= congestion_index < high:
                return level
        return "SEVERE"

    def _compute_shap_features(self, feature_vector: np.ndarray) -> list[dict[str, Any]]:
        if self._explainer is None:
            return []

        try:
            shap_values = self._explainer.shap_values(feature_vector)
            shap_vals = shap_values[0]

            abs_shap = np.abs(shap_vals)
            top_idx = np.argsort(abs_shap)[::-1][:5]

            top_features = []
            for idx in top_idx:
                if idx < len(FEATURE_NAMES):
                    top_features.append({
                        "feature": FEATURE_NAMES[idx],
                        "importance": round(float(abs_shap[idx]), 4),
                        "shap_value": round(float(shap_vals[idx]), 4),
                        "value": round(float(feature_vector[0][idx]), 4),
                        "direction": "increases_congestion" if shap_vals[idx] > 0 else "decreases_congestion",
                    })
            return top_features
        except Exception as exc:
            logger.warning(f"SHAP computation failed: {exc}")
            return []

    def train(self, df: pd.DataFrame) -> dict[str, float]:
        """
        Train the traffic predictor on historical (or synthetic bootstrap)
        traffic data.

        Args:
            df: DataFrame with columns matching FEATURE_NAMES's raw inputs
                plus 'congestion_index' (float, 0-1 target).

        Returns:
            dict of training metrics (mae, rmse, r2).
        """
        from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

        logger.info(f"Training TrafficPredictor on {len(df)} samples...")

        self._zone_encoder.fit(df["zone_id"].astype(str))

        X = np.array([
            self._engineer_features({
                "hour": row["hour"],
                "day_of_week": row["day_of_week"],
                "month": row["month"],
                "zone_id": str(row["zone_id"]),
                "weather_code": row.get("weather_code", 0),
                "base_speed_kmh": row.get("base_speed_kmh", 50.0),
                "nearby_incidents_24h": row.get("nearby_incidents_24h", 0),
                "event_nearby": bool(row.get("event_nearby", False)),
            })
            for _, row in df.iterrows()
        ], dtype=np.float32)

        y = df["congestion_index"].values

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        self._model = XGBRegressor(**self._base_regressor_params)
        self._model.fit(X_train, y_train)

        try:
            self._explainer = shap.TreeExplainer(self._model)
        except Exception as e:
            logger.warning(f"Could not create SHAP explainer: {e}")

        y_pred = self._model.predict(X_test)

        metrics = {
            "mae": float(mean_absolute_error(y_test, y_pred)),
            "rmse": float(mean_squared_error(y_test, y_pred) ** 0.5),
            "r2": float(r2_score(y_test, y_pred)),
            "training_samples": int(len(X_train)),
            "test_samples": int(len(X_test)),
        }

        self._is_trained = True
        self._trained_at = datetime.utcnow()
        self._training_metrics = metrics

        logger.info(f"TrafficPredictor trained: R2={metrics['r2']:.4f}, MAE={metrics['mae']:.4f}")
        return metrics

    def save(self, path: str) -> None:
        os.makedirs(path, exist_ok=True)
        save_data = {
            "model": self._model,
            "zone_encoder": self._zone_encoder,
            "is_trained": self._is_trained,
            "trained_at": self._trained_at,
            "training_metrics": self._training_metrics,
        }
        joblib.dump(save_data, os.path.join(path, "traffic_predictor.joblib"), compress=3)
        logger.info(f"TrafficPredictor saved to {path}")

    def load(self, path: str) -> None:
        save_data = joblib.load(path)
        self._model = save_data["model"]
        self._zone_encoder = save_data["zone_encoder"]
        self._is_trained = save_data["is_trained"]
        self._trained_at = save_data["trained_at"]
        self._training_metrics = save_data.get("training_metrics", {})

        if self._model is not None:
            try:
                self._explainer = shap.TreeExplainer(self._model)
            except Exception:
                pass

        logger.info(f"TrafficPredictor loaded from {path}")

    def get_status(self) -> dict[str, Any]:
        return {
            "model_type": "XGBoostRegressor",
            "is_trained": self._is_trained,
            "trained_at": self._trained_at.isoformat() if self._trained_at else None,
            "features": FEATURE_NAMES,
            "metrics": self._training_metrics,
            "explainability": "SHAP TreeExplainer" if self._explainer else "Unavailable",
        }

"""
SecureCity AI — CrimePredictor Model
XGBoost-based crime risk classification with SHAP explainability.
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
from sklearn.calibration import CalibratedClassifierCV
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier

# Risk level thresholds
RISK_THRESHOLDS = {
    "LOW": (0.0, 0.25),
    "MEDIUM": (0.25, 0.50),
    "HIGH": (0.50, 0.75),
    "CRITICAL": (0.75, 1.0),
}

FEATURE_NAMES = [
    "hour",
    "day_of_week",
    "month",
    "zone_id_encoded",
    "weather_code",
    "historical_rate",
    "population_density",
    "nearby_incidents_24h",
    # Engineered features
    "is_night",
    "is_weekend",
    "is_rush_hour",
    "hour_sin",
    "hour_cos",
    "day_sin",
    "day_cos",
]


class CrimePredictor:
    """
    XGBoost-based crime risk classifier with calibrated probabilities
    and SHAP-based explainability.

    Features:
        - hour (0-23)
        - day_of_week (0=Monday, 6=Sunday)
        - month (1-12)
        - zone_id (categorical, encoded)
        - weather_code (int — 0=clear, 1=cloudy, 2=rain, 3=storm, 4=fog)
        - historical_rate (incidents per km² per day)
        - population_density (persons per km²)
        - nearby_incidents_24h (count)

    Output:
        - risk_score: float [0, 1]
        - risk_level: str (LOW/MEDIUM/HIGH/CRITICAL)
        - confidence: float [0, 1]
        - top_features: list of {feature, importance, value}
    """

    def __init__(self) -> None:
        self._model: CalibratedClassifierCV | None = None
        self._zone_encoder = LabelEncoder()
        self._explainer: shap.TreeExplainer | None = None
        self._is_trained: bool = False
        self._trained_at: datetime | None = None
        self._training_metrics: dict[str, float] = {}

        # Initialize XGBoost base classifier
        self._base_classifier = XGBClassifier(
            n_estimators=300,
            max_depth=6,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            min_child_weight=3,
            gamma=0.1,
            reg_alpha=0.1,
            reg_lambda=1.0,
            use_label_encoder=False,
            eval_metric="logloss",
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

        # Cyclical time encoding
        hour_sin = np.sin(2 * np.pi * hour / 24)
        hour_cos = np.cos(2 * np.pi * hour / 24)
        day_sin = np.sin(2 * np.pi * day_of_week / 7)
        day_cos = np.cos(2 * np.pi * day_of_week / 7)

        # Binary flags
        is_night = 1 if (hour >= 22 or hour <= 5) else 0
        is_weekend = 1 if day_of_week >= 5 else 0
        is_rush_hour = 1 if (7 <= hour <= 9 or 17 <= hour <= 19) else 0

        # Zone encoding
        zone_id = features.get("zone_id", "unknown")
        try:
            zone_id_encoded = self._zone_encoder.transform([zone_id])[0]
        except (ValueError, AttributeError):
            zone_id_encoded = 0  # Unknown zone defaults to 0

        return np.array([
            hour,
            day_of_week,
            features.get("month", 1),
            zone_id_encoded,
            features.get("weather_code", 0),
            features.get("historical_rate", 0.0),
            features.get("population_density", 1000.0),
            features.get("nearby_incidents_24h", 0),
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
        historical_rate: float = 0.0,
        population_density: float = 1000.0,
        nearby_incidents_24h: int = 0,
    ) -> dict[str, Any]:
        """
        Predict crime risk for given spatiotemporal features.

        Returns:
            dict containing:
                - risk_score: float [0, 1]
                - risk_level: str
                - confidence: float [0, 1]
                - top_features: list of feature importance dicts
                - prediction_time_ms: float
        """
        if not self._is_trained or self._model is None:
            # Return neutral prediction for untrained model
            return {
                "risk_score": 0.3,
                "risk_level": "LOW",
                "confidence": 0.0,
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
            "historical_rate": historical_rate,
            "population_density": population_density,
            "nearby_incidents_24h": nearby_incidents_24h,
        }

        feature_vector = self._engineer_features(features).reshape(1, -1)

        # Calibrated probability prediction
        proba = self._model.predict_proba(feature_vector)[0]
        risk_score = float(proba[1])  # Probability of crime event

        # Risk level
        risk_level = self._get_risk_level(risk_score)

        # Confidence — distance from decision boundary (0.5)
        confidence = float(abs(risk_score - 0.5) * 2)

        # SHAP explainability
        top_features = self._compute_shap_features(feature_vector, risk_score)

        elapsed_ms = (time.monotonic() - start) * 1000

        return {
            "risk_score": round(risk_score, 4),
            "risk_level": risk_level,
            "confidence": round(confidence, 4),
            "top_features": top_features,
            "model_trained": True,
            "prediction_time_ms": round(elapsed_ms, 2),
        }

    def classify_severity(
        self,
        incident_type: str,
        description: str,
        zone_id: str,
        hour: int,
    ) -> dict[str, Any]:
        """
        Classify the severity of an incident on a 1-5 scale.
        Uses heuristic rules + risk model as fallback.
        """
        # Severity mapping by incident type
        type_severity_map = {
            "assault": 4,
            "robbery": 4,
            "murder": 5,
            "kidnapping": 5,
            "theft": 3,
            "vandalism": 2,
            "suspicious": 2,
            "noise": 1,
            "fire": 5,
            "medical": 5,
            "drug": 3,
            "harassment": 3,
            "missing": 5,
            "accident": 4,
        }

        base_severity = type_severity_map.get(incident_type.lower(), 3)

        # Keywords in description that increase severity
        critical_keywords = ["weapon", "gun", "knife", "blood", "unconscious", "dead", "explosion"]
        for kw in critical_keywords:
            if kw.lower() in description.lower():
                base_severity = min(5, base_severity + 1)
                break

        # Night-time increases severity
        if hour >= 22 or hour <= 5:
            base_severity = min(5, base_severity + 1)

        severity_labels = {1: "Minor", 2: "Low", 3: "Moderate", 4: "High", 5: "Critical"}
        return {
            "severity": base_severity,
            "label": severity_labels[base_severity],
            "confidence": 0.75,
            "reasoning": f"Based on incident type '{incident_type}' and contextual factors.",
        }

    def _get_risk_level(self, risk_score: float) -> str:
        for level, (low, high) in RISK_THRESHOLDS.items():
            if low <= risk_score < high:
                return level
        return "CRITICAL"

    def _compute_shap_features(
        self, feature_vector: np.ndarray, risk_score: float
    ) -> list[dict[str, Any]]:
        """Compute SHAP values for interpretability."""
        if self._explainer is None:
            return []

        try:
            shap_values = self._explainer.shap_values(feature_vector)
            if isinstance(shap_values, list):
                # Binary classification — use positive class
                shap_vals = shap_values[1][0]
            else:
                shap_vals = shap_values[0]

            # Top 5 features by absolute SHAP value
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
                        "direction": "increases_risk" if shap_vals[idx] > 0 else "decreases_risk",
                    })
            return top_features

        except Exception as exc:
            logger.warning(f"SHAP computation failed: {exc}")
            return []

    def train(self, df: pd.DataFrame) -> dict[str, float]:
        """
        Train the crime predictor on historical incident data.

        Args:
            df: DataFrame with columns matching FEATURE_NAMES plus 'target' (0/1)

        Returns:
            dict of training metrics (accuracy, precision, recall, f1, auc)
        """
        from sklearn.metrics import (
            accuracy_score, precision_score, recall_score,
            f1_score, roc_auc_score
        )

        logger.info(f"Training CrimePredictor on {len(df)} samples...")

        # Fit zone encoder
        self._zone_encoder.fit(df["zone_id"].astype(str))

        # Build feature matrix
        X = np.array([
            self._engineer_features({
                "hour": row["hour"],
                "day_of_week": row["day_of_week"],
                "month": row["month"],
                "zone_id": str(row["zone_id"]),
                "weather_code": row.get("weather_code", 0),
                "historical_rate": row.get("historical_rate", 0.0),
                "population_density": row.get("population_density", 1000.0),
                "nearby_incidents_24h": row.get("nearby_incidents_24h", 0),
            })
            for _, row in df.iterrows()
        ], dtype=np.float32)

        y = df["target"].values

        # Train/test split
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )

        # Calibrated classifier (Platt scaling)
        self._model = CalibratedClassifierCV(
            self._base_classifier,
            method="sigmoid",
            cv=5,
        )
        self._model.fit(X_train, y_train)

        # Build SHAP explainer on base model
        try:
            base_model = self._model.calibrated_classifiers_[0].estimator
            self._explainer = shap.TreeExplainer(base_model)
        except Exception as e:
            logger.warning(f"Could not create SHAP explainer: {e}")

        # Evaluate
        y_pred = self._model.predict(X_test)
        y_proba = self._model.predict_proba(X_test)[:, 1]

        metrics = {
            "accuracy": float(accuracy_score(y_test, y_pred)),
            "precision": float(precision_score(y_test, y_pred, zero_division=0)),
            "recall": float(recall_score(y_test, y_pred, zero_division=0)),
            "f1": float(f1_score(y_test, y_pred, zero_division=0)),
            "auc_roc": float(roc_auc_score(y_test, y_proba)),
            "training_samples": int(len(X_train)),
            "test_samples": int(len(X_test)),
        }

        self._is_trained = True
        self._trained_at = datetime.utcnow()
        self._training_metrics = metrics

        logger.info(f"CrimePredictor trained: AUC={metrics['auc_roc']:.4f}, F1={metrics['f1']:.4f}")
        return metrics

    def save(self, path: str) -> None:
        """Save model and encoders to disk."""
        os.makedirs(path, exist_ok=True)
        save_data = {
            "model": self._model,
            "zone_encoder": self._zone_encoder,
            "is_trained": self._is_trained,
            "trained_at": self._trained_at,
            "training_metrics": self._training_metrics,
        }
        joblib.dump(save_data, os.path.join(path, "crime_predictor.joblib"), compress=3)
        logger.info(f"CrimePredictor saved to {path}")

    def load(self, path: str) -> None:
        """Load model and encoders from disk."""
        save_data = joblib.load(path)
        self._model = save_data["model"]
        self._zone_encoder = save_data["zone_encoder"]
        self._is_trained = save_data["is_trained"]
        self._trained_at = save_data["trained_at"]
        self._training_metrics = save_data.get("training_metrics", {})

        # Rebuild SHAP explainer
        if self._model is not None:
            try:
                base_model = self._model.calibrated_classifiers_[0].estimator
                self._explainer = shap.TreeExplainer(base_model)
            except Exception:
                pass

        logger.info(f"CrimePredictor loaded from {path}")

    def get_status(self) -> dict[str, Any]:
        """Return model status for health/status endpoint."""
        return {
            "model_type": "XGBoostClassifier (Calibrated)",
            "is_trained": self._is_trained,
            "trained_at": self._trained_at.isoformat() if self._trained_at else None,
            "features": FEATURE_NAMES,
            "metrics": self._training_metrics,
            "explainability": "SHAP TreeExplainer" if self._explainer else "Unavailable",
        }

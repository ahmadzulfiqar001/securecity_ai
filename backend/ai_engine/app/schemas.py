"""
SecureCity AI — AI Engine Pydantic Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field, field_validator


# ─────────────────────────────────────────────────────────────
# Health
# ─────────────────────────────────────────────────────────────
class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    checks: dict[str, bool] = {}
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


# ─────────────────────────────────────────────────────────────
# Crime Prediction
# ─────────────────────────────────────────────────────────────
class CrimePredictionRequest(BaseModel):
    hour: int = Field(..., ge=0, le=23, description="Hour of day (0-23)")
    day_of_week: int = Field(..., ge=0, le=6, description="Day of week (0=Mon, 6=Sun)")
    month: int = Field(..., ge=1, le=12)
    zone_id: str = Field(..., description="Geographic zone identifier")
    weather_code: int = Field(default=0, ge=0, le=4, description="0=clear 1=cloudy 2=rain 3=storm 4=fog")
    historical_rate: float = Field(default=0.0, ge=0.0, description="Historical incidents per km²/day")
    population_density: float = Field(default=1000.0, ge=0.0, description="Persons per km²")
    nearby_incidents_24h: int = Field(default=0, ge=0, description="Recent incident count within zone")


class FeatureImportance(BaseModel):
    feature: str
    importance: float
    shap_value: float
    value: float
    direction: str


class CrimePredictionResponse(BaseModel):
    risk_score: float = Field(..., ge=0.0, le=1.0)
    risk_level: str = Field(..., description="LOW/MEDIUM/HIGH/CRITICAL")
    confidence: float = Field(..., ge=0.0, le=1.0)
    top_features: list[FeatureImportance] = []
    model_trained: bool = True
    prediction_time_ms: float = 0.0


# ─────────────────────────────────────────────────────────────
# Safety Score
# ─────────────────────────────────────────────────────────────
class SafetyScoreRequest(BaseModel):
    zone_id: str
    crime_rate: float = Field(default=0.5, ge=0.0)
    incident_count_24h: int = Field(default=0, ge=0)
    avg_response_time_minutes: float = Field(default=8.0, ge=0.0)
    lighting_score: float = Field(default=0.7, ge=0.0, le=1.0)
    population_density: float = Field(default=2000.0, ge=0.0)
    hour: int = Field(default=12, ge=0, le=23)


class SafetyScoreResponse(BaseModel):
    zone_id: str
    safety_score: float = Field(..., ge=0.0, le=100.0)
    safety_level: str
    factor_scores: dict[str, float]
    factor_weights: dict[str, float]
    recommendations: list[str]
    computed_at: str


# ─────────────────────────────────────────────────────────────
# Heatmap
# ─────────────────────────────────────────────────────────────
class HeatmapRequest(BaseModel):
    days: int = Field(default=30, ge=1, le=365)
    incident_type: str | None = None
    min_lat: float = 24.8
    max_lat: float = 25.0
    min_lon: float = 66.9
    max_lon: float = 67.2


class HeatmapFeatureProperties(BaseModel):
    density: float
    intensity: float
    risk_level: str


class HeatmapFeature(BaseModel):
    type: str = "Feature"
    geometry: dict[str, Any]
    properties: HeatmapFeatureProperties


class HeatmapMetadata(BaseModel):
    incident_count: int
    days: int
    incident_type: str | None
    generated_at: str
    grid_resolution: int = 50
    max_density: float = 0.0


class HeatmapResponse(BaseModel):
    type: str = "FeatureCollection"
    features: list[dict[str, Any]]
    metadata: dict[str, Any]


# ─────────────────────────────────────────────────────────────
# Incident Severity
# ─────────────────────────────────────────────────────────────
class IncidentSeverityRequest(BaseModel):
    incident_type: str
    description: str = ""
    zone_id: str = "unknown"
    hour: int = Field(default=12, ge=0, le=23)


class IncidentSeverityResponse(BaseModel):
    severity: int = Field(..., ge=1, le=5)
    severity_label: str
    confidence: float
    reasoning: str


# ─────────────────────────────────────────────────────────────
# Route Safety
# ─────────────────────────────────────────────────────────────
class RouteSafetyRequest(BaseModel):
    coordinates: list[list[float]] = Field(..., min_length=2, description="List of [lon, lat] pairs")
    hour: int = Field(default=12, ge=0, le=23)

    @field_validator("coordinates")
    @classmethod
    def validate_coordinates(cls, v: list[list[float]]) -> list[list[float]]:
        for coord in v:
            if len(coord) != 2:
                raise ValueError("Each coordinate must be [lon, lat]")
        return v


class RouteSafetyResponse(BaseModel):
    overall_score: float
    overall_level: str
    segment_count: int
    segment_scores: list[dict[str, Any]]
    danger_zones: list[dict[str, Any]]
    has_danger_zones: bool
    recommendation: str


# ─────────────────────────────────────────────────────────────
# Traffic Prediction
# ─────────────────────────────────────────────────────────────
class TrafficPredictionRequest(BaseModel):
    hour: int = Field(..., ge=0, le=23)
    day_of_week: int = Field(..., ge=0, le=6)
    month: int = Field(..., ge=1, le=12)
    zone_id: str = Field(..., description="Geographic zone identifier")
    weather_code: int = Field(default=0, ge=0, le=4, description="0=clear 1=cloudy 2=rain 3=storm 4=fog")
    base_speed_kmh: float = Field(default=50.0, gt=0.0, description="Free-flow speed for the road/zone")
    nearby_incidents_24h: int = Field(default=0, ge=0)
    event_nearby: bool = Field(default=False, description="Large gathering/event flag")


class TrafficPredictionResponse(BaseModel):
    congestion_index: float = Field(..., ge=0.0, le=1.0)
    congestion_level: str = Field(..., description="LOW/MODERATE/HEAVY/SEVERE")
    estimated_delay_minutes: float
    top_features: list[FeatureImportance] = []
    model_trained: bool = True
    prediction_time_ms: float = 0.0


# ─────────────────────────────────────────────────────────────
# Emergency Severity (SOS urgency triage)
# ─────────────────────────────────────────────────────────────
class EmergencySeverityRequest(BaseModel):
    seconds_since_triggered: float = Field(..., ge=0.0)
    area_safety_score: float = Field(default=50.0, ge=0.0, le=100.0)
    hour: int = Field(default=12, ge=0, le=23)
    repeat_trigger_count_24h: int = Field(default=0, ge=0)
    message: str | None = None
    user_is_moving: bool = False


class EmergencySeverityResponse(BaseModel):
    urgency_score: float = Field(..., ge=0.0, le=100.0)
    priority_level: str = Field(..., description="LOW/MEDIUM/HIGH/CRITICAL")
    reasoning: str
    model_trained: bool = False


# ─────────────────────────────────────────────────────────────
# Model Status
# ─────────────────────────────────────────────────────────────
class ModelStatusResponse(BaseModel):
    crime_predictor: dict[str, Any]
    safety_scorer: dict[str, Any]
    traffic_predictor: dict[str, Any]
    emergency_severity_scorer: dict[str, Any]
    active_models: int
    model_path: str


# ─────────────────────────────────────────────────────────────
# Retrain
# ─────────────────────────────────────────────────────────────
class RetrainRequest(BaseModel):
    model_name: str = Field(default="crime_predictor", pattern="^(crime_predictor|safety_scorer|traffic_predictor)$")
    days_of_data: int = Field(default=365, ge=30, le=3650)
    force: bool = False


# ─────────────────────────────────────────────────────────────
# Incidents-Geo Cache Sync
# Called by the syncIncidentGeoCache Cloud Function (functions/src/index.ts)
# whenever a Firestore `incidents` document is created, updated, or deleted.
# See backend/docs/mongodb-schema.md.
# ─────────────────────────────────────────────────────────────
class IncidentGeoSyncRequest(BaseModel):
    # `longitude`/`latitude`/`incident_type` are only required when
    # action == "upsert" — enforced in the endpoint (app/main.py), since a
    # `delete` action only needs `incident_id`.
    action: str = Field(..., pattern="^(upsert|delete)$")
    incident_id: str
    longitude: float | None = None
    latitude: float | None = None
    incident_type: str | None = None
    severity: str | None = None
    zone_id: str | None = None
    status: str | None = None
    created_at: datetime | None = None

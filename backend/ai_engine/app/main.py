"""
SecureCity AI — AI Engine FastAPI Application
Provides ML-powered predictions for crime, safety scoring, and heatmaps.
"""

from __future__ import annotations

import asyncio
import os
from contextlib import asynccontextmanager
from typing import Any

import redis.asyncio as aioredis
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends, Security
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
from loguru import logger
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
import time

from app.models.crime_predictor import CrimePredictor
from app.models.safety_scorer import SafetyScorer
from app.models.traffic_predictor import TrafficPredictor
from app.models.emergency_severity_scorer import EmergencySeverityScorer
from app.services.heatmap_service import HeatmapService
from app.core import database as db_module
from app.core.ml_repository import log_inference, upsert_incident_geo, delete_incident_geo
from app.schemas import (
    CrimePredictionRequest,
    CrimePredictionResponse,
    SafetyScoreRequest,
    SafetyScoreResponse,
    HeatmapRequest,
    HeatmapResponse,
    IncidentSeverityRequest,
    IncidentSeverityResponse,
    RouteSafetyRequest,
    RouteSafetyResponse,
    TrafficPredictionRequest,
    TrafficPredictionResponse,
    EmergencySeverityRequest,
    EmergencySeverityResponse,
    ModelStatusResponse,
    RetrainRequest,
    IncidentGeoSyncRequest,
    HealthResponse,
)
from app.config import Settings
from shared.firebase_auth import init_firebase_app, verify_firebase_token

# ─────────────────────────────────────────────────────────────
# Settings
# ─────────────────────────────────────────────────────────────
settings = Settings()

# ─────────────────────────────────────────────────────────────
# Prometheus Metrics
# ─────────────────────────────────────────────────────────────
PREDICTION_REQUESTS = Counter(
    "securecity_ai_prediction_requests_total",
    "Total prediction requests",
    ["endpoint", "status"],
)
PREDICTION_LATENCY = Histogram(
    "securecity_ai_prediction_duration_seconds",
    "Prediction latency in seconds",
    ["endpoint"],
    buckets=[0.1, 0.5, 1.0, 2.5, 5.0, 10.0],
)
ACTIVE_MODELS = Gauge(
    "securecity_ai_active_models",
    "Number of active ML models",
)
MODEL_TRAINING_COUNTER = Counter(
    "securecity_ai_model_retrains_total",
    "Total model retraining events",
    ["model_name", "status"],
)

# ─────────────────────────────────────────────────────────────
# App State (singleton services)
# ─────────────────────────────────────────────────────────────
crime_predictor: CrimePredictor | None = None
safety_scorer: SafetyScorer | None = None
traffic_predictor: TrafficPredictor | None = None
emergency_severity_scorer: EmergencySeverityScorer | None = None
heatmap_service: HeatmapService | None = None
redis_client: aioredis.Redis | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan — load models and connect services on startup."""
    global crime_predictor, safety_scorer, traffic_predictor, emergency_severity_scorer, heatmap_service, redis_client

    logger.info("🚀 SecureCity AI Engine starting up...")

    # Firebase Admin SDK (verifies the ID tokens mobile/dashboard already
    # send on every request) — degrades to 503 on gated routes rather than
    # crashing startup if no valid credentials file is configured.
    init_firebase_app(settings.FIREBASE_CREDENTIALS_PATH)

    # Connect Redis
    redis_client = aioredis.from_url(
        settings.REDIS_URL,
        encoding="utf-8",
        decode_responses=True,
        max_connections=20,
    )
    await redis_client.ping()
    logger.info("✅ Redis connected")

    # Connect MongoDB (internal ML data only — see backend/docs/mongodb-schema.md)
    await db_module.connect_db(settings)

    # Load ML models
    crime_predictor = CrimePredictor()
    model_path = os.path.join(settings.MODEL_PATH, "crime_predictor.joblib")
    if os.path.exists(model_path):
        crime_predictor.load(model_path)
        logger.info("✅ Crime predictor model loaded")
    else:
        logger.warning("⚠️  No saved crime predictor model found — using untrained model")

    safety_scorer = SafetyScorer()
    logger.info("✅ Safety scorer initialized")

    traffic_predictor = TrafficPredictor()
    traffic_model_path = os.path.join(settings.MODEL_PATH, "traffic_predictor.joblib")
    if os.path.exists(traffic_model_path):
        traffic_predictor.load(traffic_model_path)
        logger.info("✅ Traffic predictor model loaded")
    else:
        logger.warning("⚠️  No saved traffic predictor model found — using untrained model")

    emergency_severity_scorer = EmergencySeverityScorer()
    logger.info("✅ Emergency severity scorer initialized")

    heatmap_service = HeatmapService(database=db_module.get_database(), redis_client=redis_client)
    logger.info("✅ Heatmap service initialized")

    ACTIVE_MODELS.set(4)  # crime_predictor + safety_scorer + traffic_predictor + emergency_severity_scorer

    logger.info("🎯 AI Engine ready to serve predictions")
    yield

    # Cleanup
    logger.info("🛑 AI Engine shutting down...")
    if redis_client:
        await redis_client.aclose()
    await db_module.close_db()
    logger.info("✅ Cleanup complete")


# ─────────────────────────────────────────────────────────────
# FastAPI App
# ─────────────────────────────────────────────────────────────
app = FastAPI(
    title="SecureCity AI Engine",
    description="Machine learning predictions for crime risk, safety scoring, and heatmap generation.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# ─────────────────────────────────────────────────────────────
# Middleware
# ─────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Mount Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Security
security = HTTPBearer(auto_error=False)


async def verify_internal_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> dict[str, Any]:
    """Verify internal service-to-service token."""
    if credentials is None or credentials.credentials != settings.INTERNAL_SERVICE_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid service token")
    return {"authenticated": True}


# ─────────────────────────────────────────────────────────────
# Dependencies
# ─────────────────────────────────────────────────────────────
async def get_redis() -> aioredis.Redis:
    if redis_client is None:
        raise HTTPException(status_code=503, detail="Redis not available")
    return redis_client


async def get_crime_predictor() -> CrimePredictor:
    if crime_predictor is None:
        raise HTTPException(status_code=503, detail="Crime predictor not loaded")
    return crime_predictor


async def get_safety_scorer() -> SafetyScorer:
    if safety_scorer is None:
        raise HTTPException(status_code=503, detail="Safety scorer not loaded")
    return safety_scorer


async def get_traffic_predictor() -> TrafficPredictor:
    if traffic_predictor is None:
        raise HTTPException(status_code=503, detail="Traffic predictor not loaded")
    return traffic_predictor


async def get_emergency_severity_scorer() -> EmergencySeverityScorer:
    if emergency_severity_scorer is None:
        raise HTTPException(status_code=503, detail="Emergency severity scorer not loaded")
    return emergency_severity_scorer


async def get_heatmap_service() -> HeatmapService:
    if heatmap_service is None:
        raise HTTPException(status_code=503, detail="Heatmap service not available")
    return heatmap_service


# ─────────────────────────────────────────────────────────────
# Health Check
# ─────────────────────────────────────────────────────────────
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check() -> HealthResponse:
    """Service health check endpoint."""
    checks: dict[str, bool] = {}

    # Check Redis
    try:
        await redis_client.ping()
        checks["redis"] = True
    except Exception:
        checks["redis"] = False

    # Check models
    checks["crime_predictor"] = crime_predictor is not None and crime_predictor.is_trained
    checks["safety_scorer"] = safety_scorer is not None
    checks["traffic_predictor"] = traffic_predictor is not None
    checks["emergency_severity_scorer"] = emergency_severity_scorer is not None

    all_healthy = all(checks.values())
    return HealthResponse(
        status="healthy" if all_healthy else "degraded",
        service="ai_engine",
        version="1.0.0",
        checks=checks,
    )


# ─────────────────────────────────────────────────────────────
# Crime Prediction
# ─────────────────────────────────────────────────────────────
@app.post(
    "/predict/crime",
    response_model=CrimePredictionResponse,
    tags=["Predictions"],
    summary="Predict crime risk for a location and time",
    dependencies=[Depends(verify_firebase_token)],
)
async def predict_crime(
    request: CrimePredictionRequest,
    background_tasks: BackgroundTasks,
    redis: aioredis.Redis = Depends(get_redis),
    predictor: CrimePredictor = Depends(get_crime_predictor),
) -> CrimePredictionResponse:
    """
    Predict the crime risk for a given geographic area and time window.

    Returns a risk score (0-1), risk level (LOW/MEDIUM/HIGH/CRITICAL),
    confidence score, and SHAP-based feature importances.
    """
    start = time.monotonic()
    PREDICTION_REQUESTS.labels(endpoint="crime", status="started").inc()

    # Cache key
    cache_key = f"crime_pred:{request.zone_id}:{request.hour}:{request.day_of_week}"
    cached = await redis.get(cache_key)
    if cached:
        import json
        PREDICTION_REQUESTS.labels(endpoint="crime", status="cache_hit").inc()
        return CrimePredictionResponse(**json.loads(cached))

    try:
        result = predictor.predict(
            hour=request.hour,
            day_of_week=request.day_of_week,
            month=request.month,
            zone_id=request.zone_id,
            weather_code=request.weather_code,
            historical_rate=request.historical_rate,
            population_density=request.population_density,
            nearby_incidents_24h=request.nearby_incidents_24h,
        )
        response = CrimePredictionResponse(**result)

        # Cache for 5 minutes
        import json
        await redis.setex(cache_key, 300, json.dumps(response.model_dump()))

        PREDICTION_REQUESTS.labels(endpoint="crime", status="success").inc()
        elapsed_ms = (time.monotonic() - start) * 1000
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/crime",
            model_name="crime_predictor",
            status="success",
            request_summary={"zone_id": request.zone_id, "hour": request.hour},
            result_summary={"risk_level": response.risk_level, "risk_score": response.risk_score},
            confidence=response.confidence,
            latency_ms=elapsed_ms,
        )
        return response

    except Exception as exc:
        PREDICTION_REQUESTS.labels(endpoint="crime", status="error").inc()
        logger.error(f"Crime prediction error: {exc}")
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/crime",
            model_name="crime_predictor",
            status="error",
            request_summary={"zone_id": request.zone_id, "hour": request.hour},
            error_message=str(exc),
        )
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(exc)}")
    finally:
        elapsed = time.monotonic() - start
        PREDICTION_LATENCY.labels(endpoint="crime").observe(elapsed)


# ─────────────────────────────────────────────────────────────
# Safety Score
# ─────────────────────────────────────────────────────────────
@app.post(
    "/predict/safety-score",
    response_model=SafetyScoreResponse,
    tags=["Predictions"],
    summary="Compute comprehensive safety score for an area",
    dependencies=[Depends(verify_firebase_token)],
)
async def predict_safety_score(
    request: SafetyScoreRequest,
    background_tasks: BackgroundTasks,
    redis: aioredis.Redis = Depends(get_redis),
    scorer: SafetyScorer = Depends(get_safety_scorer),
) -> SafetyScoreResponse:
    """
    Compute a 0-100 safety score for a geographic area based on multiple factors:
    crime rate, incident count, response time, lighting, population density, time of day.
    """
    start = time.monotonic()
    PREDICTION_REQUESTS.labels(endpoint="safety_score", status="started").inc()

    cache_key = f"safety_score:{request.zone_id}:{request.hour}"
    cached = await redis.get(cache_key)
    if cached:
        import json
        return SafetyScoreResponse(**json.loads(cached))

    try:
        result = scorer.compute_score(
            zone_id=request.zone_id,
            crime_rate=request.crime_rate,
            incident_count_24h=request.incident_count_24h,
            avg_response_time_minutes=request.avg_response_time_minutes,
            lighting_score=request.lighting_score,
            population_density=request.population_density,
            hour=request.hour,
        )
        response = SafetyScoreResponse(**result)

        import json
        await redis.setex(cache_key, 3600, json.dumps(response.model_dump()))
        PREDICTION_REQUESTS.labels(endpoint="safety_score", status="success").inc()
        elapsed_ms = (time.monotonic() - start) * 1000
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/safety-score",
            model_name="safety_scorer",
            status="success",
            request_summary={"zone_id": request.zone_id, "hour": request.hour},
            result_summary={"safety_score": response.safety_score, "safety_level": response.safety_level},
            latency_ms=elapsed_ms,
        )
        return response

    except Exception as exc:
        PREDICTION_REQUESTS.labels(endpoint="safety_score", status="error").inc()
        logger.error(f"Safety score error: {exc}")
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/safety-score",
            model_name="safety_scorer",
            status="error",
            request_summary={"zone_id": request.zone_id, "hour": request.hour},
            error_message=str(exc),
        )
        raise HTTPException(status_code=500, detail=str(exc))
    finally:
        elapsed = time.monotonic() - start
        PREDICTION_LATENCY.labels(endpoint="safety_score").observe(elapsed)


# ─────────────────────────────────────────────────────────────
# Heatmap
# ─────────────────────────────────────────────────────────────
@app.get(
    "/predict/heatmap",
    response_model=HeatmapResponse,
    tags=["Predictions"],
    summary="Generate crime density heatmap data",
    dependencies=[Depends(verify_firebase_token)],
)
async def get_heatmap(
    days: int = 30,
    incident_type: str | None = None,
    min_lat: float = 24.8,
    max_lat: float = 25.0,
    min_lon: float = 66.9,
    max_lon: float = 67.2,
    service: HeatmapService = Depends(get_heatmap_service),
    redis: aioredis.Redis = Depends(get_redis),
) -> HeatmapResponse:
    """
    Generate a KDE-based crime density heatmap as a GeoJSON FeatureCollection.
    Supports filtering by time range (7/30/90 days) and incident type.
    """
    start = time.monotonic()
    cache_key = f"heatmap:{days}:{incident_type}:{min_lat:.3f}:{max_lat:.3f}:{min_lon:.3f}:{max_lon:.3f}"

    cached = await redis.get(cache_key)
    if cached:
        import json
        return HeatmapResponse(**json.loads(cached))

    try:
        result = await service.generate_heatmap(
            days=days,
            incident_type=incident_type,
            bounds=(min_lat, max_lat, min_lon, max_lon),
        )
        response = HeatmapResponse(**result)

        import json
        await redis.setex(cache_key, 3600, json.dumps(response.model_dump()))
        return response

    except Exception as exc:
        logger.error(f"Heatmap generation error: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))
    finally:
        elapsed = time.monotonic() - start
        PREDICTION_LATENCY.labels(endpoint="heatmap").observe(elapsed)


# ─────────────────────────────────────────────────────────────
# Incident Severity Classification
# ─────────────────────────────────────────────────────────────
@app.post(
    "/predict/incident-severity",
    response_model=IncidentSeverityResponse,
    tags=["Predictions"],
    summary="Classify the severity of a reported incident",
    dependencies=[Depends(verify_firebase_token)],
)
async def predict_incident_severity(
    request: IncidentSeverityRequest,
    background_tasks: BackgroundTasks,
    predictor: CrimePredictor = Depends(get_crime_predictor),
) -> IncidentSeverityResponse:
    """
    Classify the severity of an incident (1-5) based on its description,
    type, location, and time context using the XGBoost classifier.
    """
    start = time.monotonic()
    try:
        severity = predictor.classify_severity(
            incident_type=request.incident_type,
            description=request.description,
            zone_id=request.zone_id,
            hour=request.hour,
        )
        response = IncidentSeverityResponse(
            severity=severity["severity"],
            severity_label=severity["label"],
            confidence=severity["confidence"],
            reasoning=severity["reasoning"],
        )
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/incident-severity",
            model_name="crime_predictor",
            status="success",
            request_summary={"incident_type": request.incident_type, "zone_id": request.zone_id},
            result_summary={"severity": response.severity, "severity_label": response.severity_label},
            confidence=response.confidence,
            latency_ms=(time.monotonic() - start) * 1000,
        )
        return response
    except Exception as exc:
        logger.error(f"Severity classification error: {exc}")
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/incident-severity",
            model_name="crime_predictor",
            status="error",
            request_summary={"incident_type": request.incident_type, "zone_id": request.zone_id},
            error_message=str(exc),
        )
        raise HTTPException(status_code=500, detail=str(exc))


# ─────────────────────────────────────────────────────────────
# Route Safety Scoring
# ─────────────────────────────────────────────────────────────
@app.post(
    "/predict/route-safety",
    response_model=RouteSafetyResponse,
    tags=["Predictions"],
    summary="Score the safety of a route geometry",
    dependencies=[Depends(verify_firebase_token)],
)
async def predict_route_safety(
    request: RouteSafetyRequest,
    background_tasks: BackgroundTasks,
    scorer: SafetyScorer = Depends(get_safety_scorer),
    service: HeatmapService = Depends(get_heatmap_service),
) -> RouteSafetyResponse:
    """
    Score the overall safety of a route by sampling points along the geometry
    and aggregating safety scores from the crime heatmap.
    """
    start = time.monotonic()
    try:
        result = await scorer.score_route(
            route_coordinates=request.coordinates,
            hour=request.hour,
            heatmap_service=service,
        )
        response = RouteSafetyResponse(**result)
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/route-safety",
            status="success",
            request_summary={"segment_count": len(request.coordinates), "hour": request.hour},
            result_summary={"overall_score": response.overall_score, "overall_level": response.overall_level},
            latency_ms=(time.monotonic() - start) * 1000,
        )
        return response
    except Exception as exc:
        logger.error(f"Route safety scoring error: {exc}")
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/route-safety",
            status="error",
            request_summary={"segment_count": len(request.coordinates), "hour": request.hour},
            error_message=str(exc),
        )
        raise HTTPException(status_code=500, detail=str(exc))


# ─────────────────────────────────────────────────────────────
# Traffic Prediction
# ─────────────────────────────────────────────────────────────
@app.post(
    "/predict/traffic",
    response_model=TrafficPredictionResponse,
    tags=["Predictions"],
    summary="Predict traffic congestion for a zone and time",
    dependencies=[Depends(verify_firebase_token)],
)
async def predict_traffic(
    request: TrafficPredictionRequest,
    background_tasks: BackgroundTasks,
    predictor: TrafficPredictor = Depends(get_traffic_predictor),
) -> TrafficPredictionResponse:
    """
    Predict traffic congestion for a given zone and time window.

    Returns a congestion index (0-1), congestion level
    (LOW/MODERATE/HEAVY/SEVERE), an estimated delay in minutes, and
    SHAP-based feature importances.
    """
    start = time.monotonic()
    try:
        result = predictor.predict(
            hour=request.hour,
            day_of_week=request.day_of_week,
            month=request.month,
            zone_id=request.zone_id,
            weather_code=request.weather_code,
            base_speed_kmh=request.base_speed_kmh,
            nearby_incidents_24h=request.nearby_incidents_24h,
            event_nearby=request.event_nearby,
        )
        response = TrafficPredictionResponse(**result)
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/traffic",
            model_name="traffic_predictor",
            status="success",
            request_summary={"zone_id": request.zone_id, "hour": request.hour},
            result_summary={"congestion_level": response.congestion_level, "congestion_index": response.congestion_index},
            latency_ms=(time.monotonic() - start) * 1000,
        )
        return response
    except Exception as exc:
        logger.error(f"Traffic prediction error: {exc}")
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/traffic",
            model_name="traffic_predictor",
            status="error",
            request_summary={"zone_id": request.zone_id, "hour": request.hour},
            error_message=str(exc),
        )
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(exc)}")


# ─────────────────────────────────────────────────────────────
# Emergency Severity (SOS urgency triage)
# ─────────────────────────────────────────────────────────────
@app.post(
    "/predict/emergency-severity",
    response_model=EmergencySeverityResponse,
    tags=["Predictions"],
    summary="Score the urgency of an active SOS alert for triage",
    dependencies=[Depends(verify_firebase_token)],
)
async def predict_emergency_severity(
    request: EmergencySeverityRequest,
    background_tasks: BackgroundTasks,
    scorer: EmergencySeverityScorer = Depends(get_emergency_severity_scorer),
) -> EmergencySeverityResponse:
    """
    Score an active SOS alert's urgency (0-100) for the Emergency Queue
    dashboard, so authorities can prioritize which alert to respond to first.
    """
    start = time.monotonic()
    try:
        result = scorer.score(
            seconds_since_triggered=request.seconds_since_triggered,
            area_safety_score=request.area_safety_score,
            hour=request.hour,
            repeat_trigger_count_24h=request.repeat_trigger_count_24h,
            message=request.message,
            user_is_moving=request.user_is_moving,
        )
        response = EmergencySeverityResponse(**result)
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/emergency-severity",
            model_name="emergency_severity_scorer",
            status="success",
            request_summary={"seconds_since_triggered": request.seconds_since_triggered},
            result_summary={"priority_level": response.priority_level, "urgency_score": response.urgency_score},
            latency_ms=(time.monotonic() - start) * 1000,
        )
        return response
    except Exception as exc:
        logger.error(f"Emergency severity scoring error: {exc}")
        background_tasks.add_task(
            log_inference,
            service="ai_engine",
            endpoint="/predict/emergency-severity",
            model_name="emergency_severity_scorer",
            status="error",
            request_summary={"seconds_since_triggered": request.seconds_since_triggered},
            error_message=str(exc),
        )
        raise HTTPException(status_code=500, detail=str(exc))


# ─────────────────────────────────────────────────────────────
# Internal — Incidents-Geo Cache Sync
# Called by the syncIncidentGeoCache Cloud Function (functions/src/index.ts)
# whenever a Firestore `incidents` document is created, updated, or
# deleted, keeping the MongoDB `incidents_geo` cache (used by
# HeatmapService and crime model retraining) in sync with Firestore, the
# source of truth. See backend/docs/mongodb-schema.md.
# ─────────────────────────────────────────────────────────────
@app.post(
    "/internal/incidents-geo/sync",
    tags=["Internal"],
    summary="Sync a Firestore incident into the MongoDB incidents-geo cache (internal only)",
    dependencies=[Depends(verify_internal_token)],
)
async def sync_incident_geo(request: IncidentGeoSyncRequest) -> dict[str, str]:
    if request.action == "delete":
        await delete_incident_geo(request.incident_id)
        return {"status": "deleted", "incident_id": request.incident_id}

    # action == "upsert"
    if request.longitude is None or request.latitude is None or request.incident_type is None:
        raise HTTPException(
            status_code=422,
            detail="longitude, latitude, and incident_type are required for an upsert action",
        )

    await upsert_incident_geo(
        incident_id=request.incident_id,
        longitude=request.longitude,
        latitude=request.latitude,
        incident_type=request.incident_type,
        severity=request.severity,
        zone_id=request.zone_id,
        status=request.status,
        created_at=request.created_at,
    )
    return {"status": "upserted", "incident_id": request.incident_id}


# ─────────────────────────────────────────────────────────────
# Model Status
# ─────────────────────────────────────────────────────────────
@app.get(
    "/models/status",
    response_model=ModelStatusResponse,
    tags=["Models"],
    summary="Get model health and training metadata",
    dependencies=[Depends(verify_firebase_token)],
)
async def get_model_status(
    predictor: CrimePredictor = Depends(get_crime_predictor),
    scorer: SafetyScorer = Depends(get_safety_scorer),
    traffic: TrafficPredictor = Depends(get_traffic_predictor),
    emergency_scorer: EmergencySeverityScorer = Depends(get_emergency_severity_scorer),
) -> ModelStatusResponse:
    """Get the status of all loaded ML models including training date and performance metrics."""
    return ModelStatusResponse(
        crime_predictor=predictor.get_status(),
        safety_scorer=scorer.get_status(),
        traffic_predictor=traffic.get_status(),
        emergency_severity_scorer=emergency_scorer.get_status(),
        active_models=4,
        model_path=settings.MODEL_PATH,
    )


# ─────────────────────────────────────────────────────────────
# Model Retraining (Admin)
# ─────────────────────────────────────────────────────────────
@app.post(
    "/models/retrain",
    tags=["Models"],
    summary="Trigger model retraining (admin only)",
    dependencies=[Depends(verify_internal_token)],
)
async def retrain_models(
    request: RetrainRequest,
    background_tasks: BackgroundTasks,
    predictor: CrimePredictor = Depends(get_crime_predictor),
    traffic: TrafficPredictor = Depends(get_traffic_predictor),
) -> dict[str, str]:
    """
    Trigger asynchronous model retraining. Only accessible with a valid
    internal service token. Retraining runs in the background.
    """
    if request.model_name == "traffic_predictor":
        from app.tasks.retrain_traffic_model import retrain_traffic_model_task

        background_tasks.add_task(
            retrain_traffic_model_task,
            predictor=traffic,
            model_name=request.model_name,
            days_of_data=request.days_of_data,
            save_path=settings.MODEL_PATH,
        )
    else:
        from app.tasks.retrain_crime_model import retrain_crime_model_task

        background_tasks.add_task(
            retrain_crime_model_task,
            predictor=predictor,
            model_name=request.model_name,
            days_of_data=request.days_of_data,
            save_path=settings.MODEL_PATH,
        )
    MODEL_TRAINING_COUNTER.labels(model_name=request.model_name, status="queued").inc()
    return {
        "status": "queued",
        "message": f"Retraining of {request.model_name} queued successfully",
        "model": request.model_name,
    }


# ─────────────────────────────────────────────────────────────
# Exception Handlers
# ─────────────────────────────────────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request, exc: Exception) -> JSONResponse:
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "type": type(exc).__name__},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8001,
        reload=settings.ENVIRONMENT == "development",
        workers=1,  # Single worker for GPU/model sharing
        log_level="info",
    )

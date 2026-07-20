"""
app/core/ml_repository.py
==========================
Read/write helpers for ai_engine's internal ML collections (see
database.py), plus the aggregation pipelines documented in
backend/docs/mongodb-schema.md.

Every write helper is designed to be safe to call from a `BackgroundTasks`
callback: it never raises past its own logging, so a logging failure can
never turn into a 500 on the actual prediction/training response.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from loguru import logger
from pymongo import ReturnDocument

from app.core.database import (
    COL_CV_DETECTION_EVENTS,
    COL_INCIDENTS_GEO,
    COL_INFERENCE_LOGS,
    COL_ML_MODELS,
    COL_TRAINING_RUNS,
    get_database,
)


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Inference logging — fire-and-forget from prediction endpoints
# ---------------------------------------------------------------------------
async def log_inference(
    *,
    service: str,
    endpoint: str,
    status: str,
    model_name: str | None = None,
    request_summary: dict[str, Any] | None = None,
    result_summary: dict[str, Any] | None = None,
    confidence: float | None = None,
    latency_ms: float | None = None,
    error_message: str | None = None,
) -> None:
    try:
        db = get_database()
        await db[COL_INFERENCE_LOGS].insert_one({
            "service": service,
            "endpoint": endpoint,
            "model_name": model_name,
            "request_summary": request_summary,
            "result_summary": result_summary,
            "confidence": confidence,
            "latency_ms": latency_ms,
            "status": status,
            "error_message": error_message,
            "created_at": _utcnow(),
        })
    except Exception as exc:  # noqa: BLE001 — logging must never break the caller
        logger.warning(f"Failed to write inference log for '{endpoint}': {exc}")


# ---------------------------------------------------------------------------
# CV detection events — security-relevant detections only
# ---------------------------------------------------------------------------
async def log_cv_detection_event(
    *,
    camera_id: str,
    frame_id: str,
    detections: list[dict[str, Any]],
    threat_classes: list[str],
    max_confidence: float,
    processing_time_ms: float,
    forwarded_to_firestore: bool = False,
    firestore_doc_id: str | None = None,
) -> None:
    try:
        db = get_database()
        await db[COL_CV_DETECTION_EVENTS].insert_one({
            "camera_id": camera_id,
            "frame_id": frame_id,
            "detections": detections,
            "threat_classes": threat_classes,
            "max_confidence": max_confidence,
            "processing_time_ms": processing_time_ms,
            "forwarded_to_firestore": forwarded_to_firestore,
            "firestore_doc_id": firestore_doc_id,
            "created_at": _utcnow(),
        })
    except Exception as exc:  # noqa: BLE001
        logger.warning(f"Failed to write cv_detection_event for camera '{camera_id}': {exc}")


# ---------------------------------------------------------------------------
# Model registry
# ---------------------------------------------------------------------------
async def upsert_model_registry(
    *,
    name: str,
    version: str,
    service: str,
    status: str,
    algorithm: str | None = None,
    file_path: str | None = None,
    hyperparameters: dict[str, Any] | None = None,
    metrics: dict[str, Any] | None = None,
    trained_at: datetime | None = None,
) -> None:
    db = get_database()
    now = _utcnow()
    await db[COL_ML_MODELS].find_one_and_update(
        {"name": name, "version": version},
        {
            "$set": {
                "service": service,
                "algorithm": algorithm,
                "status": status,
                "file_path": file_path,
                "hyperparameters": hyperparameters,
                "metrics": metrics,
                "trained_at": trained_at,
                "updated_at": now,
            },
            "$setOnInsert": {"created_at": now},
        },
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )
    logger.info(f"Model registry updated: {name} v{version} ({status})")


# ---------------------------------------------------------------------------
# Training runs
# ---------------------------------------------------------------------------
async def record_training_run(
    *,
    model_name: str,
    started_at: datetime,
    status: str,
    triggered_by: str,
    model_version: str | None = None,
    dataset_id: Any = None,
    completed_at: datetime | None = None,
    hyperparameters: dict[str, Any] | None = None,
    metrics: dict[str, Any] | None = None,
    sample_count: int | None = None,
    error_message: str | None = None,
) -> str:
    db = get_database()
    result = await db[COL_TRAINING_RUNS].insert_one({
        "model_name": model_name,
        "model_version": model_version,
        "dataset_id": dataset_id,
        "started_at": started_at,
        "completed_at": completed_at,
        "status": status,
        "triggered_by": triggered_by,
        "hyperparameters": hyperparameters,
        "metrics": metrics,
        "sample_count": sample_count,
        "error_message": error_message,
    })
    return str(result.inserted_id)


# ---------------------------------------------------------------------------
# Incidents-geo cache — synced from Firestore via syncIncidentGeoCache
# (functions/src/index.ts) calling POST /internal/incidents-geo/sync
# ---------------------------------------------------------------------------
async def upsert_incident_geo(
    *,
    incident_id: str,
    longitude: float,
    latitude: float,
    incident_type: str,
    severity: str | None = None,
    zone_id: str | None = None,
    status: str | None = None,
    created_at: datetime | None = None,
) -> None:
    db = get_database()
    await db[COL_INCIDENTS_GEO].replace_one(
        {"_id": incident_id},
        {
            "_id": incident_id,
            "location": {"type": "Point", "coordinates": [longitude, latitude]},
            "incident_type": incident_type,
            "severity": severity,
            "zone_id": zone_id,
            "status": status,
            "created_at": created_at or _utcnow(),
            "synced_at": _utcnow(),
        },
        upsert=True,
    )


async def delete_incident_geo(incident_id: str) -> None:
    db = get_database()
    await db[COL_INCIDENTS_GEO].delete_one({"_id": incident_id})


# ---------------------------------------------------------------------------
# Aggregation pipelines (documented in backend/docs/mongodb-schema.md)
# ---------------------------------------------------------------------------
async def model_performance_trend(model_name: str, weeks: int = 8) -> list[dict[str, Any]]:
    """Weekly average of each numeric metric key for a model's training runs."""
    db = get_database()
    pipeline = [
        {"$match": {"model_name": model_name, "status": "completed"}},
        {"$sort": {"started_at": -1}},
        {"$limit": weeks},
        {
            "$project": {
                "week_start": {
                    "$dateTrunc": {"date": "$started_at", "unit": "week"},
                },
                "metrics": 1,
            }
        },
        {"$sort": {"week_start": 1}},
    ]
    return await db[COL_TRAINING_RUNS].aggregate(pipeline).to_list(length=weeks)


async def inference_volume_by_endpoint(days: int = 7) -> list[dict[str, Any]]:
    """Daily request count and average latency per endpoint, for capacity planning."""
    db = get_database()
    since = _utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    pipeline = [
        {"$match": {"created_at": {"$gte": since}}},
        {
            "$group": {
                "_id": {
                    "endpoint": "$endpoint",
                    "day": {"$dateTrunc": {"date": "$created_at", "unit": "day"}},
                },
                "request_count": {"$sum": 1},
                "avg_latency_ms": {"$avg": "$latency_ms"},
                "error_count": {
                    "$sum": {"$cond": [{"$eq": ["$status", "error"]}, 1, 0]},
                },
            }
        },
        {"$sort": {"_id.day": -1, "_id.endpoint": 1}},
    ]
    return await db[COL_INFERENCE_LOGS].aggregate(pipeline).to_list(length=None)


async def crime_density_by_zone(days: int = 30) -> list[dict[str, Any]]:
    """Incident count per zone over the trailing window, from the synced geo cache."""
    db = get_database()
    since = _utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    pipeline = [
        {"$match": {"created_at": {"$gte": since}, "zone_id": {"$ne": None}}},
        {
            "$group": {
                "_id": "$zone_id",
                "incident_count": {"$sum": 1},
                "types": {"$addToSet": "$incident_type"},
            }
        },
        {"$sort": {"incident_count": -1}},
    ]
    return await db[COL_INCIDENTS_GEO].aggregate(pipeline).to_list(length=None)

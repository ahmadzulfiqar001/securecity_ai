"""
app/core/database.py
=====================
MongoDB (Motor) lifecycle, index management, and JSON Schema validation for
ai_engine's own internal ML operational data.

This is NOT app data storage — Users/Incidents/Notifications/etc. live in
Firestore. See backend/docs/mongodb-schema.md for the full design (ER
diagram, index rationale, aggregation pipelines, backup strategy). This
module only wires up what that document describes:

* ``ml_models``          — model registry (one doc per name+version)
* ``training_runs``      — training job history
* ``training_datasets``  — dataset version metadata
* ``inference_logs``     — every prediction call (TTL 90 days)
* ``cv_detection_events``— cv_engine's security-relevant detections (TTL 180 days)
* ``incidents_geo``      — read-only cache of Firestore ``incidents``,
  kept current by the ``syncIncidentGeoCache`` Cloud Function
  (functions/src/index.ts), used for KDE heatmap generation and model
  retraining feature extraction.
"""

from __future__ import annotations

from loguru import logger
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import ASCENDING, DESCENDING, GEOSPHERE, IndexModel
from pymongo.errors import OperationFailure

from app.config import Settings

# Collection names — import these, don't hardcode the strings elsewhere.
COL_ML_MODELS = "ml_models"
COL_TRAINING_RUNS = "training_runs"
COL_TRAINING_DATASETS = "training_datasets"
COL_INFERENCE_LOGS = "inference_logs"
COL_CV_DETECTION_EVENTS = "cv_detection_events"
COL_INCIDENTS_GEO = "incidents_geo"

# TTL retention windows.
INFERENCE_LOGS_TTL_SECONDS = 90 * 24 * 3600
CV_DETECTION_EVENTS_TTL_SECONDS = 180 * 24 * 3600

_client: AsyncIOMotorClient | None = None
_database: AsyncIOMotorDatabase | None = None

# ---------------------------------------------------------------------------
# Index definitions
# ---------------------------------------------------------------------------
_INDEXES: dict[str, list[IndexModel]] = {
    COL_ML_MODELS: [
        IndexModel([("name", ASCENDING), ("version", ASCENDING)], unique=True, name="uidx_name_version"),
        IndexModel([("status", ASCENDING)], name="idx_status"),
        IndexModel([("service", ASCENDING)], name="idx_service"),
    ],
    COL_TRAINING_RUNS: [
        IndexModel([("model_name", ASCENDING), ("started_at", DESCENDING)], name="idx_model_started"),
        IndexModel([("status", ASCENDING)], name="idx_status"),
    ],
    COL_TRAINING_DATASETS: [
        IndexModel([("name", ASCENDING), ("version", ASCENDING)], unique=True, name="uidx_name_version"),
    ],
    COL_INFERENCE_LOGS: [
        IndexModel([("endpoint", ASCENDING), ("created_at", DESCENDING)], name="idx_endpoint_created"),
        IndexModel([("model_name", ASCENDING)], name="idx_model_name"),
        IndexModel(
            [("created_at", ASCENDING)],
            name="ttl_inference_logs",
            expireAfterSeconds=INFERENCE_LOGS_TTL_SECONDS,
        ),
    ],
    COL_CV_DETECTION_EVENTS: [
        IndexModel([("camera_id", ASCENDING), ("created_at", DESCENDING)], name="idx_camera_created"),
        IndexModel([("threat_classes", ASCENDING)], name="idx_threat_classes"),
        IndexModel(
            [("created_at", ASCENDING)],
            name="ttl_cv_detection_events",
            expireAfterSeconds=CV_DETECTION_EVENTS_TTL_SECONDS,
        ),
    ],
    COL_INCIDENTS_GEO: [
        IndexModel([("location", GEOSPHERE)], name="idx_location_2dsphere"),
        IndexModel([("incident_type", ASCENDING), ("created_at", DESCENDING)], name="idx_type_created"),
        IndexModel([("zone_id", ASCENDING)], name="idx_zone_id"),
    ],
}

# ---------------------------------------------------------------------------
# JSON Schema validators — enforced by MongoDB itself, not just Pydantic at
# the API boundary, so direct writes (admin scripts, the sync endpoint) are
# held to the same shape.
# ---------------------------------------------------------------------------
_VALIDATORS: dict[str, dict] = {
    COL_ML_MODELS: {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["name", "version", "service", "status", "created_at"],
            "properties": {
                "name": {"bsonType": "string"},
                "version": {"bsonType": "string"},
                "service": {"enum": ["ai_engine", "cv_engine"]},
                "algorithm": {"bsonType": ["string", "null"]},
                "status": {"enum": ["training", "active", "deprecated", "failed"]},
                "file_path": {"bsonType": ["string", "null"]},
                "hyperparameters": {"bsonType": ["object", "null"]},
                "metrics": {"bsonType": ["object", "null"]},
                "trained_at": {"bsonType": ["date", "null"]},
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": ["date", "null"]},
            },
        }
    },
    COL_TRAINING_RUNS: {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["model_name", "started_at", "status", "triggered_by"],
            "properties": {
                "model_name": {"bsonType": "string"},
                "model_version": {"bsonType": ["string", "null"]},
                "dataset_id": {"bsonType": ["objectId", "null"]},
                "started_at": {"bsonType": "date"},
                "completed_at": {"bsonType": ["date", "null"]},
                "status": {"enum": ["running", "completed", "failed"]},
                "triggered_by": {"enum": ["scheduled", "manual", "api"]},
                "hyperparameters": {"bsonType": ["object", "null"]},
                "metrics": {"bsonType": ["object", "null"]},
                "sample_count": {"bsonType": ["int", "long", "null"]},
                "error_message": {"bsonType": ["string", "null"]},
            },
        }
    },
    COL_TRAINING_DATASETS: {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["name", "version", "source", "created_at"],
            "properties": {
                "name": {"bsonType": "string"},
                "version": {"bsonType": "string"},
                "source": {"bsonType": "string"},
                "record_count": {"bsonType": ["int", "long", "null"]},
                "date_range_start": {"bsonType": ["date", "null"]},
                "date_range_end": {"bsonType": ["date", "null"]},
                "feature_schema": {"bsonType": ["object", "null"]},
                "quality_metrics": {"bsonType": ["object", "null"]},
                "storage_location": {"bsonType": ["string", "null"]},
                "created_at": {"bsonType": "date"},
            },
        }
    },
    COL_INFERENCE_LOGS: {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["service", "endpoint", "status", "created_at"],
            "properties": {
                "service": {"bsonType": "string"},
                "endpoint": {"bsonType": "string"},
                "model_name": {"bsonType": ["string", "null"]},
                "request_summary": {"bsonType": ["object", "null"]},
                "result_summary": {"bsonType": ["object", "null"]},
                "confidence": {"bsonType": ["double", "int", "null"]},
                "latency_ms": {"bsonType": ["double", "int", "null"]},
                "status": {"enum": ["success", "error"]},
                "error_message": {"bsonType": ["string", "null"]},
                "created_at": {"bsonType": "date"},
            },
        }
    },
    COL_CV_DETECTION_EVENTS: {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["camera_id", "frame_id", "detections", "created_at"],
            "properties": {
                "camera_id": {"bsonType": "string"},
                "frame_id": {"bsonType": "string"},
                "detections": {"bsonType": "array"},
                "threat_classes": {"bsonType": ["array", "null"]},
                "max_confidence": {"bsonType": ["double", "int", "null"]},
                "processing_time_ms": {"bsonType": ["double", "int", "null"]},
                "forwarded_to_firestore": {"bsonType": ["bool", "null"]},
                "firestore_doc_id": {"bsonType": ["string", "null"]},
                "created_at": {"bsonType": "date"},
            },
        }
    },
    COL_INCIDENTS_GEO: {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["location", "incident_type", "created_at"],
            "properties": {
                "location": {
                    "bsonType": "object",
                    "required": ["type", "coordinates"],
                    "properties": {
                        "type": {"enum": ["Point"]},
                        "coordinates": {"bsonType": "array"},
                    },
                },
                "incident_type": {"bsonType": "string"},
                "severity": {"bsonType": ["string", "null"]},
                "zone_id": {"bsonType": ["string", "null"]},
                "status": {"bsonType": ["string", "null"]},
                "created_at": {"bsonType": "date"},
                "synced_at": {"bsonType": ["date", "null"]},
            },
        }
    },
}


# ---------------------------------------------------------------------------
# Connection lifecycle
# ---------------------------------------------------------------------------
async def connect_db(settings: Settings) -> None:
    """Open the Motor client, verify connectivity, and ensure schema.

    Idempotent — safe to call multiple times in the same process (e.g. the
    Celery retraining task calls this on every run; only the first call in
    a given worker process actually opens a connection).

    No retry loop here — docker-compose's `depends_on: mongodb: condition:
    service_healthy` (see docker-compose.yml) already guarantees Mongo is
    up and accepting connections before this service starts, matching how
    the Redis connection in main.py is handled.
    """
    global _client, _database

    if _client is not None:
        return

    logger.info(f"Connecting to MongoDB database '{settings.MONGODB_DB_NAME}'...")

    _client = AsyncIOMotorClient(
        settings.MONGODB_URL,
        serverSelectionTimeoutMS=10_000,
        connectTimeoutMS=10_000,
        maxPoolSize=20,
        minPoolSize=2,
    )
    _database = _client[settings.MONGODB_DB_NAME]

    await _database.command("ping")
    await _ensure_collections_and_validators()
    await _ensure_indexes()
    logger.info(f"MongoDB connected: {settings.MONGODB_DB_NAME}")


async def close_db() -> None:
    """Close the Motor client on application shutdown."""
    global _client, _database
    if _client is not None:
        _client.close()
        _client = None
        _database = None
        logger.info("MongoDB disconnected")


def get_database() -> AsyncIOMotorDatabase:
    if _database is None:
        raise RuntimeError("Database is not connected. Ensure connect_db() is called during startup.")
    return _database


# ---------------------------------------------------------------------------
# Schema management
# ---------------------------------------------------------------------------
async def _ensure_collections_and_validators() -> None:
    """Create each collection with its validator if missing, or update the
    validator in place (`collMod`) if the collection already exists —
    idempotent either way."""
    db = get_database()
    existing = set(await db.list_collection_names())

    for name, validator in _VALIDATORS.items():
        try:
            if name not in existing:
                await db.create_collection(name, validator=validator, validationLevel="moderate")
                logger.debug(f"MongoDB collection created: {name}")
            else:
                await db.command("collMod", name, validator=validator, validationLevel="moderate")
                logger.debug(f"MongoDB validator updated: {name}")
        except OperationFailure as exc:
            logger.warning(f"MongoDB validator setup warning for '{name}': {exc}")


async def _ensure_indexes() -> None:
    """Create all collection indexes idempotently (create_indexes is safe to re-run)."""
    db = get_database()
    for collection_name, indexes in _INDEXES.items():
        try:
            result = await db[collection_name].create_indexes(indexes)
            logger.debug(f"MongoDB indexes ensured for '{collection_name}': {result}")
        except OperationFailure as exc:
            logger.warning(f"MongoDB index creation warning for '{collection_name}': {exc}")

"""
app/core/database.py
=====================
MongoDB (Motor) lifecycle for cv_engine's own internal ML data.

Scoped to just `cv_detection_events` — the only collection this service
writes to (security-relevant detections only, not every analyzed frame).
Shares the same `securecity_ml` database as ai_engine (see
backend/docs/mongodb-schema.md) but each service manages its own
connection and schema setup since they run as separate processes.
"""

from __future__ import annotations

from datetime import datetime, timezone

from loguru import logger
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import ASCENDING, IndexModel
from pymongo.errors import OperationFailure

from app.config import Settings

COL_CV_DETECTION_EVENTS = "cv_detection_events"
CV_DETECTION_EVENTS_TTL_SECONDS = 180 * 24 * 3600  # 180 days

_VALIDATOR = {
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
}

_INDEXES = [
    IndexModel([("camera_id", ASCENDING), ("created_at", -1)], name="idx_camera_created"),
    IndexModel([("threat_classes", ASCENDING)], name="idx_threat_classes"),
    IndexModel(
        [("created_at", ASCENDING)],
        name="ttl_cv_detection_events",
        expireAfterSeconds=CV_DETECTION_EVENTS_TTL_SECONDS,
    ),
]

_client: AsyncIOMotorClient | None = None
_database: AsyncIOMotorDatabase | None = None


async def connect_db(settings: Settings) -> None:
    """Open the Motor client and ensure the collection/index/validator exist.

    Idempotent — safe to call multiple times in the same process. No
    retry loop — docker-compose's `depends_on: mongodb: condition:
    service_healthy` already guarantees Mongo is reachable before this
    service starts.
    """
    global _client, _database

    if _client is not None:
        return

    logger.info(f"Connecting to MongoDB database '{settings.MONGODB_DB_NAME}'...")
    _client = AsyncIOMotorClient(
        settings.MONGODB_URL,
        serverSelectionTimeoutMS=10_000,
        connectTimeoutMS=10_000,
        maxPoolSize=10,
        minPoolSize=1,
    )
    _database = _client[settings.MONGODB_DB_NAME]
    await _database.command("ping")

    existing = set(await _database.list_collection_names())
    try:
        if COL_CV_DETECTION_EVENTS not in existing:
            await _database.create_collection(
                COL_CV_DETECTION_EVENTS, validator=_VALIDATOR, validationLevel="moderate"
            )
        else:
            await _database.command(
                "collMod", COL_CV_DETECTION_EVENTS, validator=_VALIDATOR, validationLevel="moderate"
            )
    except OperationFailure as exc:
        logger.warning(f"MongoDB validator setup warning for '{COL_CV_DETECTION_EVENTS}': {exc}")

    try:
        await _database[COL_CV_DETECTION_EVENTS].create_indexes(_INDEXES)
    except OperationFailure as exc:
        logger.warning(f"MongoDB index creation warning for '{COL_CV_DETECTION_EVENTS}': {exc}")

    logger.info(f"MongoDB connected: {settings.MONGODB_DB_NAME}")


async def close_db() -> None:
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


async def log_cv_detection_event(
    *,
    camera_id: str,
    frame_id: str,
    detections: list[dict],
    threat_classes: list[str],
    max_confidence: float,
    processing_time_ms: float,
) -> None:
    """Fire-and-forget write — never raises past its own logging, so a
    logging failure can never turn into a 500 on the analysis response."""
    try:
        db = get_database()
        await db[COL_CV_DETECTION_EVENTS].insert_one({
            "camera_id": camera_id,
            "frame_id": frame_id,
            "detections": detections,
            "threat_classes": threat_classes,
            "max_confidence": max_confidence,
            "processing_time_ms": processing_time_ms,
            "forwarded_to_firestore": False,
            "firestore_doc_id": None,
            "created_at": datetime.now(timezone.utc),
        })
    except Exception as exc:  # noqa: BLE001
        logger.warning(f"Failed to write cv_detection_event for camera '{camera_id}': {exc}")

"""
SecureCity AI — Daily crime model retraining Celery task
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta
from typing import Any

from celery import shared_task
from loguru import logger


@shared_task(
    bind=True,
    name="ai_engine.tasks.retrain_crime_model",
    max_retries=3,
    default_retry_delay=300,
    acks_late=True,
)
def retrain_crime_model_celery(self) -> dict[str, Any]:
    """
    Celery task for scheduled daily crime model retraining.
    Fetches last N days of incident data from MongoDB and retrains.
    """
    import asyncio
    return asyncio.run(_retrain_async())


async def _retrain_async() -> dict[str, Any]:
    import pandas as pd
    from app.config import Settings
    from app.core import database as db_module
    from app.core.database import COL_INCIDENTS_GEO
    from app.core.ml_repository import record_training_run, upsert_model_registry
    from app.models.crime_predictor import CrimePredictor

    settings = Settings()
    model_path = os.environ.get("MODEL_PATH", settings.MODEL_PATH)
    started_at = datetime.utcnow()

    logger.info("🔄 Starting daily crime model retraining...")

    await db_module.connect_db(settings)
    db = db_module.get_database()

    since = datetime.utcnow() - timedelta(days=365)
    # Reads from incidents_geo — a MongoDB cache of Firestore's `incidents`
    # collection (the real source of truth), kept current by the
    # syncIncidentGeoCache Cloud Function. See backend/docs/mongodb-schema.md.
    cursor = db[COL_INCIDENTS_GEO].find(
        {"created_at": {"$gte": since}},
        {
            "location": 1, "created_at": 1, "incident_type": 1,
            "severity": 1, "zone_id": 1, "_id": 0,
        }
    ).limit(100000)

    records = []
    async for doc in cursor:
        try:
            created = doc["created_at"]
            records.append({
                "hour": created.hour,
                "day_of_week": created.weekday(),
                "month": created.month,
                "zone_id": doc.get("zone_id") or "unknown",
                "weather_code": 0,
                "historical_rate": 1.0,
                "population_density": 2000.0,
                "nearby_incidents_24h": 0,
                "target": 1,
            })
        except Exception:
            continue

    if len(records) < 100:
        logger.warning(f"Insufficient training data: {len(records)} samples")
        await record_training_run(
            model_name="crime_predictor",
            started_at=started_at,
            completed_at=datetime.utcnow(),
            status="failed",
            triggered_by="scheduled",
            sample_count=len(records),
            error_message=f"Insufficient training data: {len(records)} samples (minimum 100)",
        )
        return {"status": "skipped", "reason": "insufficient_data", "count": len(records)}

    # Add negative samples (no-crime examples)
    import random
    negatives = []
    for _ in range(len(records)):
        negatives.append({
            "hour": random.randint(0, 23),
            "day_of_week": random.randint(0, 6),
            "month": random.randint(1, 12),
            "zone_id": random.choice(["zone_a", "zone_b", "zone_c"]),
            "weather_code": random.randint(0, 4),
            "historical_rate": random.uniform(0, 0.5),
            "population_density": random.uniform(500, 5000),
            "nearby_incidents_24h": 0,
            "target": 0,
        })

    df = pd.DataFrame(records + negatives).sample(frac=1, random_state=42).reset_index(drop=True)

    predictor = CrimePredictor()
    try:
        metrics = predictor.train(df)
    except Exception as exc:
        logger.error(f"❌ Training failed: {exc}")
        await record_training_run(
            model_name="crime_predictor",
            started_at=started_at,
            completed_at=datetime.utcnow(),
            status="failed",
            triggered_by="scheduled",
            sample_count=len(df),
            error_message=str(exc),
        )
        raise

    predictor.save(model_path)
    completed_at = datetime.utcnow()

    await record_training_run(
        model_name="crime_predictor",
        started_at=started_at,
        completed_at=completed_at,
        status="completed",
        triggered_by="scheduled",
        metrics=metrics,
        sample_count=len(df),
    )
    await upsert_model_registry(
        name="crime_predictor",
        version=completed_at.strftime("%Y%m%d%H%M%S"),
        service="ai_engine",
        algorithm="XGBoostClassifier (Calibrated)",
        status="active",
        file_path=os.path.join(model_path, "crime_predictor.joblib"),
        metrics=metrics,
        trained_at=completed_at,
    )

    logger.info(f"✅ Retraining complete: {metrics}")
    return {"status": "success", "metrics": metrics, "samples": len(df)}


async def retrain_crime_model_task(
    predictor: Any,
    model_name: str,
    days_of_data: int,
    save_path: str,
) -> dict[str, Any]:
    """Background task version for FastAPI BackgroundTasks."""
    import pandas as pd

    logger.info(f"Starting background retraining of {model_name} ({days_of_data} days)")
    try:
        result = await _retrain_async()
        logger.info(f"✅ Background retraining complete: {result}")
        return result
    except Exception as exc:
        logger.error(f"❌ Background retraining failed: {exc}")
        return {"status": "failed", "error": str(exc)}

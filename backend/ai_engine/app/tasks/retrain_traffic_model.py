"""
SecureCity AI — Traffic congestion model retraining Celery task
"""

from __future__ import annotations

import os
from datetime import datetime
from typing import Any

from celery import shared_task
from loguru import logger


@shared_task(
    bind=True,
    name="ai_engine.tasks.retrain_traffic_model",
    max_retries=3,
    default_retry_delay=300,
    acks_late=True,
)
def retrain_traffic_model_celery(self) -> dict[str, Any]:
    """Celery task for scheduled traffic model retraining."""
    import asyncio
    return asyncio.run(_retrain_async())


async def _retrain_async() -> dict[str, Any]:
    from app.config import Settings
    from app.core import database as db_module
    from app.core.ml_repository import record_training_run, upsert_model_registry
    from app.data.synthetic_traffic_dataset import generate_synthetic_traffic_dataset
    from app.models.traffic_predictor import TrafficPredictor

    settings = Settings()
    model_path = os.environ.get("MODEL_PATH", settings.MODEL_PATH)
    started_at = datetime.utcnow()

    logger.info("🔄 Starting traffic model retraining...")

    await db_module.connect_db(settings)

    # No real `traffic_data` collection exists yet (no sensor/camera feed) —
    # see app/data/synthetic_traffic_dataset.py for why a synthetic bootstrap
    # is used here instead of a real query.
    df = generate_synthetic_traffic_dataset(n_samples=5000, seed=42)

    predictor = TrafficPredictor()
    try:
        metrics = predictor.train(df)
    except Exception as exc:
        logger.error(f"❌ Traffic training failed: {exc}")
        await record_training_run(
            model_name="traffic_predictor",
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
        model_name="traffic_predictor",
        started_at=started_at,
        completed_at=completed_at,
        status="completed",
        triggered_by="scheduled",
        metrics=metrics,
        sample_count=len(df),
    )
    await upsert_model_registry(
        name="traffic_predictor",
        version=completed_at.strftime("%Y%m%d%H%M%S"),
        service="ai_engine",
        algorithm="XGBoostRegressor",
        status="active",
        file_path=os.path.join(model_path, "traffic_predictor.joblib"),
        metrics=metrics,
        trained_at=completed_at,
    )

    logger.info(f"✅ Traffic retraining complete: {metrics}")
    return {"status": "success", "metrics": metrics, "samples": len(df)}


async def retrain_traffic_model_task(
    predictor: Any,
    model_name: str,
    days_of_data: int,
    save_path: str,
) -> dict[str, Any]:
    """Background task version for FastAPI BackgroundTasks."""
    logger.info(f"Starting background retraining of {model_name}")
    try:
        result = await _retrain_async()
        logger.info(f"✅ Background traffic retraining complete: {result}")
        return result
    except Exception as exc:
        logger.error(f"❌ Background traffic retraining failed: {exc}")
        return {"status": "failed", "error": str(exc)}

"""
SecureCity AI — Celery application for ai_engine's scheduled ML retraining.

app/tasks/retrain_crime_model.py and app/tasks/retrain_traffic_model.py
already declare @shared_task-decorated functions ("ai_engine.tasks.
retrain_crime_model" / "ai_engine.tasks.retrain_traffic_model"), and
celery==5.4.0 has been a dependency for a while — but until now nothing
ever instantiated an actual Celery() app for them to bind to, so no
worker or beat scheduler could run them. This module is that app;
docker-compose.yml's celery-worker/celery-beat services point at it.

Run locally with:
    celery -A app.celery_app:celery_app worker --loglevel=info
    celery -A app.celery_app:celery_app beat --loglevel=info
"""

from __future__ import annotations

from celery import Celery
from celery.schedules import crontab

from app.config import Settings

settings = Settings()

celery_app = Celery(
    "ai_engine",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.tasks.retrain_crime_model",
        "app.tasks.retrain_traffic_model",
    ],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
)

celery_app.conf.beat_schedule = {
    "daily-crime-model-retrain": {
        "task": "ai_engine.tasks.retrain_crime_model",
        "schedule": crontab(hour=2, minute=0),
    },
    "daily-traffic-model-retrain": {
        "task": "ai_engine.tasks.retrain_traffic_model",
        "schedule": crontab(hour=3, minute=0),
    },
}

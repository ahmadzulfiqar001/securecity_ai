"""Celery task: update safety scores for all zones hourly."""

from __future__ import annotations

import os
from datetime import datetime
from typing import Any

from loguru import logger


async def update_safety_scores_task() -> dict[str, Any]:
    """Refresh safety scores for all geographic zones."""
    from motor.motor_asyncio import AsyncIOMotorClient
    import redis.asyncio as aioredis
    import json

    mongo_url = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
    redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/1")

    mongo_client = AsyncIOMotorClient(mongo_url)
    redis_client = aioredis.from_url(redis_url, decode_responses=True)

    from app.models.safety_scorer import SafetyScorer
    scorer = SafetyScorer()

    db = mongo_client["securecity_nosql"]
    zones_cursor = db["safety_zones"].find({}, {"zone_id": 1, "stats": 1})

    updated = 0
    failed = 0
    hour = datetime.utcnow().hour

    async for zone in zones_cursor:
        try:
            zone_id = str(zone["_id"])
            stats = zone.get("stats", {})

            result = scorer.compute_score(
                zone_id=zone_id,
                crime_rate=stats.get("crime_rate", 0.5),
                incident_count_24h=stats.get("incident_count_24h", 0),
                avg_response_time_minutes=stats.get("avg_response_time_minutes", 8.0),
                lighting_score=stats.get("lighting_score", 0.7),
                population_density=stats.get("population_density", 2000.0),
                hour=hour,
            )

            cache_key = f"safety_score:{zone_id}"
            await redis_client.setex(cache_key, 7200, json.dumps(result))

            await db["safety_zones"].update_one(
                {"_id": zone["_id"]},
                {
                    "$set": {
                        "current_safety_score": result["safety_score"],
                        "safety_level": result["safety_level"],
                        "score_updated_at": datetime.utcnow(),
                    }
                },
            )
            updated += 1

        except Exception as exc:
            logger.error(f"Failed to update safety score for zone {zone.get('_id')}: {exc}")
            failed += 1

    await redis_client.aclose()
    mongo_client.close()

    logger.info(f"Safety scores updated: {updated} success, {failed} failed")
    return {"updated": updated, "failed": failed, "hour": hour}

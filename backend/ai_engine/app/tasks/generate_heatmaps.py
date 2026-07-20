"""Celery task: generate heatmaps every 6 hours."""

from __future__ import annotations

import os
from datetime import datetime
from typing import Any

from loguru import logger


async def generate_heatmaps_task() -> dict[str, Any]:
    """Pre-generate and cache heatmaps for common time windows."""
    from motor.motor_asyncio import AsyncIOMotorClient
    import redis.asyncio as aioredis
    import json

    mongo_url = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
    redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/1")

    mongo_client = AsyncIOMotorClient(mongo_url)
    redis_client = aioredis.from_url(redis_url, decode_responses=True)

    from app.services.heatmap_service import HeatmapService
    service = HeatmapService(mongo_client=mongo_client, redis_client=redis_client)

    # Default city bounds (Karachi example)
    bounds = (24.8, 25.0, 66.9, 67.2)
    generated = 0

    for days in [7, 30, 90]:
        try:
            result = await service.generate_heatmap(days=days, bounds=bounds)
            cache_key = f"heatmap:{days}:None:{bounds[0]:.3f}:{bounds[1]:.3f}:{bounds[2]:.3f}:{bounds[3]:.3f}"
            await redis_client.setex(cache_key, 21600, json.dumps(result))  # 6h TTL
            generated += 1
            logger.info(f"Heatmap generated for {days} days: {result['metadata']['incident_count']} incidents")
        except Exception as exc:
            logger.error(f"Heatmap generation failed for {days} days: {exc}")

    await redis_client.aclose()
    mongo_client.close()

    return {"generated": generated, "generated_at": datetime.utcnow().isoformat()}

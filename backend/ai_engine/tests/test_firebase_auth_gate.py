"""
Tests that CRIT-01's Firebase auth gate actually rejects unauthenticated
requests to citizen/authority-facing routes.

Boots the real FastAPI app (via its lifespan, same pattern as
test_incidents_geo_sync.py), so this needs a reachable MongoDB and Redis.
conftest.py points FIREBASE_CREDENTIALS_PATH at a generated fake-but-
valid credentials file so the Firebase Admin SDK actually initializes
(verify_firebase_token would otherwise 503 with no Firebase configured
at all, which would hide whether the 401 "missing token" branch works).
"""

from __future__ import annotations

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def client():
    from app.main import app

    async with app.router.lifespan_context(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as async_client:
            yield async_client


async def test_models_status_rejects_missing_token(client: AsyncClient):
    response = await client.get("/models/status")
    assert response.status_code == 401


async def test_models_status_rejects_invalid_token(client: AsyncClient):
    response = await client.get(
        "/models/status", headers={"Authorization": "Bearer not-a-real-firebase-token"}
    )
    assert response.status_code == 401


async def test_health_stays_public(client: AsyncClient):
    """/health must never require a token — used by Docker healthchecks."""
    response = await client.get("/health")
    assert response.status_code == 200

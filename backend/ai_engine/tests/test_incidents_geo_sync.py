"""
Tests for POST /internal/incidents-geo/sync — the endpoint the
syncIncidentGeoCache Cloud Function (functions/src/index.ts) calls on
every Firestore `incidents` create/update/delete.

Boots the real FastAPI app (via its lifespan), so this needs a reachable
MongoDB *and* Redis — see conftest.py / backend/docs/mongodb-schema.md.

Deliberately does not share the `db` fixture from conftest.py: the app's
own lifespan already owns connect/close for `app.core.database`, and
nesting two independent lifecycles around the same module-level client
would race on teardown. Tests reach the database via
`app.core.database.get_database()` once the app fixture has entered the
lifespan, and this file cleans up its own `incidents_geo` documents.
"""

from __future__ import annotations

import datetime

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.core.database import COL_INCIDENTS_GEO, get_database

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def client():
    from app.main import app

    async with app.router.lifespan_context(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as async_client:
            yield async_client
        await get_database()[COL_INCIDENTS_GEO].delete_many({})


async def test_sync_rejects_missing_token(client: AsyncClient):
    response = await client.post(
        "/internal/incidents-geo/sync",
        json={"action": "upsert", "incident_id": "x", "longitude": 1.0, "latitude": 2.0, "incident_type": "OTHER"},
    )
    assert response.status_code == 401


async def test_sync_rejects_invalid_token(client: AsyncClient):
    response = await client.post(
        "/internal/incidents-geo/sync",
        json={"action": "upsert", "incident_id": "x", "longitude": 1.0, "latitude": 2.0, "incident_type": "OTHER"},
        headers={"Authorization": "Bearer wrong-token"},
    )
    assert response.status_code == 401


async def test_sync_upsert_persists_to_incidents_geo(client: AsyncClient):
    response = await client.post(
        "/internal/incidents-geo/sync",
        json={
            "action": "upsert",
            "incident_id": "incident-sync-1",
            "longitude": 67.0011,
            "latitude": 24.8607,
            "incident_type": "ROBBERY",
            "severity": "HIGH",
        },
        headers={"Authorization": "Bearer test-internal-token"},
    )
    assert response.status_code == 200
    assert response.json() == {"status": "upserted", "incident_id": "incident-sync-1"}

    doc = await get_database()[COL_INCIDENTS_GEO].find_one({"_id": "incident-sync-1"})
    assert doc is not None
    assert doc["location"]["coordinates"] == [67.0011, 24.8607]
    assert doc["severity"] == "HIGH"


async def test_sync_upsert_requires_coordinates(client: AsyncClient):
    response = await client.post(
        "/internal/incidents-geo/sync",
        json={"action": "upsert", "incident_id": "incident-sync-2", "incident_type": "OTHER"},
        headers={"Authorization": "Bearer test-internal-token"},
    )
    assert response.status_code == 422


async def test_sync_delete_removes_from_incidents_geo(client: AsyncClient):
    await get_database()[COL_INCIDENTS_GEO].insert_one({
        "_id": "incident-sync-3",
        "location": {"type": "Point", "coordinates": [1.0, 2.0]},
        "incident_type": "OTHER",
        "created_at": datetime.datetime.now(datetime.timezone.utc),
    })

    response = await client.post(
        "/internal/incidents-geo/sync",
        json={"action": "delete", "incident_id": "incident-sync-3"},
        headers={"Authorization": "Bearer test-internal-token"},
    )
    assert response.status_code == 200
    assert response.json() == {"status": "deleted", "incident_id": "incident-sync-3"}

    doc = await get_database()[COL_INCIDENTS_GEO].find_one({"_id": "incident-sync-3"})
    assert doc is None

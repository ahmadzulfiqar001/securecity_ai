"""
Shared pytest fixtures for ai_engine tests.

Requires a reachable MongoDB (and Redis, for the FastAPI app fixture) —
see backend/docs/mongodb-schema.md. In CI this comes from the `mongodb`/
`redis` service containers in .github/workflows/ci.yml; locally, run
`docker compose up mongodb redis` first.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest
import pytest_asyncio

# Make backend/shared/ (the Firebase auth module shared with cv_engine)
# importable when pytest's cwd is backend/ai_engine/ — mirrors how Docker
# already puts both app/ and shared/ on PYTHONPATH at the same level (see
# backend/ai_engine/Dockerfile). Must happen before any `app.main` import.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

os.environ.setdefault(
    "MONGODB_URL",
    "mongodb://mongoadmin:test_password@localhost:27017/securecity_ml_test?authSource=admin",
)
os.environ.setdefault("MONGODB_DB_NAME", "securecity_ml_test")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("INTERNAL_SERVICE_TOKEN", "test-internal-token")


def _write_fake_firebase_credentials() -> str:
    """
    A syntactically valid (but fake, unregistered) service-account JSON —
    enough for firebase_admin.credentials.Certificate() to parse and
    initialize_app() to succeed offline (no network call happens at init
    time). Without this, every test that boots the app would see
    verify_firebase_token's 503 "not configured" branch instead of
    exercising the real 401 "missing token" logic — there's no real
    Firebase project available in CI.
    """
    import json
    import tempfile

    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import rsa

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private_key_pem = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()

    fd, path = tempfile.mkstemp(prefix="fake_firebase_credentials_", suffix=".json")
    with os.fdopen(fd, "w") as f:
        json.dump({
            "type": "service_account",
            "project_id": "test-project",
            "private_key_id": "test-key-id",
            "private_key": private_key_pem,
            "client_email": "test@test-project.iam.gserviceaccount.com",
            "client_id": "000000000000000000000",
            "token_uri": "https://oauth2.googleapis.com/token",
        }, f)
    return path


os.environ.setdefault("FIREBASE_CREDENTIALS_PATH", _write_fake_firebase_credentials())

from app.config import Settings  # noqa: E402
from app.core import database as db_module  # noqa: E402


@pytest.fixture
def settings() -> Settings:
    return Settings()


@pytest_asyncio.fixture
async def db(settings: Settings):
    """A connected test database, wiped clean after each test."""
    await db_module.connect_db(settings)
    database = db_module.get_database()
    yield database

    for name in await database.list_collection_names():
        await database[name].delete_many({})
    await db_module.close_db()

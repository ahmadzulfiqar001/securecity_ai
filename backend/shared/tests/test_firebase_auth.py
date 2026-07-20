"""
Unit tests for shared/firebase_auth.py — no live services required.

Exercises verify_firebase_token/init_firebase_app in isolation (not via
a booted FastAPI app) by manipulating firebase_admin's global app
registry directly, so these run anywhere pytest runs.
"""

from __future__ import annotations

import firebase_admin
import pytest
from fastapi import HTTPException

from shared.firebase_auth import init_firebase_app, verify_firebase_token


@pytest.fixture(autouse=True)
def _clean_firebase_apps():
    """Firebase Admin's app registry is process-global — reset it around
    each test so tests don't leak state into each other."""
    for app in list(firebase_admin._apps.values()):
        firebase_admin.delete_app(app)
    yield
    for app in list(firebase_admin._apps.values()):
        firebase_admin.delete_app(app)


@pytest.mark.asyncio
async def test_verify_returns_503_when_firebase_not_configured():
    with pytest.raises(HTTPException) as exc_info:
        await verify_firebase_token(credentials=None)
    assert exc_info.value.status_code == 503


def test_init_firebase_app_does_not_raise_on_missing_credentials_file():
    # No exception, no app registered — degrades gracefully so /health and
    # internal-token-gated routes keep working without real credentials.
    init_firebase_app("./this/path/does/not/exist.json")
    assert firebase_admin._apps == {}


def test_init_firebase_app_is_idempotent(tmp_path):
    """Calling it twice (e.g. across module reloads in tests) must not
    raise 'app already exists', even with a real credentials file."""
    cred_path = _write_fake_service_account(tmp_path)
    init_firebase_app(str(cred_path))
    assert firebase_admin._apps != {}
    init_firebase_app(str(cred_path))  # must not raise
    assert len(firebase_admin._apps) == 1


@pytest.mark.asyncio
async def test_verify_returns_401_when_token_missing(tmp_path):
    cred_path = _write_fake_service_account(tmp_path)
    init_firebase_app(str(cred_path))

    with pytest.raises(HTTPException) as exc_info:
        await verify_firebase_token(credentials=None)
    assert exc_info.value.status_code == 401


def _write_fake_service_account(tmp_path):
    """A syntactically valid (but not a real, registered) service account
    JSON — enough for firebase_admin.credentials.Certificate() to parse
    and initialize_app() to succeed offline. No network call happens at
    init time, so this doesn't need a real Firebase project."""
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    import json

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private_key_pem = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()

    cred_path = tmp_path / "fake_service_account.json"
    cred_path.write_text(json.dumps({
        "type": "service_account",
        "project_id": "test-project",
        "private_key_id": "test-key-id",
        "private_key": private_key_pem,
        "client_email": "test@test-project.iam.gserviceaccount.com",
        "client_id": "000000000000000000000",
        "token_uri": "https://oauth2.googleapis.com/token",
    }))
    return cred_path

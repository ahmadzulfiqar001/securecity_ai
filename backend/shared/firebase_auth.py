"""
SecureCity AI — Shared Firebase ID token verification.

Both mobile and dashboard already attach `Authorization: Bearer
<FirebaseIdToken>` to every request to ai_engine/cv_engine (see
mobile/lib/core/network/api_client.dart and
dashboard/lib/core/network/api_client.dart) — neither service actually
verified it server-side until now. This module is shared (not duplicated
per-service) because the verification logic is identical for both.

Usage in a service's main.py:

    from shared.firebase_auth import init_firebase_app, verify_firebase_token

    @asynccontextmanager
    async def lifespan(app):
        init_firebase_app(settings.FIREBASE_CREDENTIALS_PATH)
        ...

    @app.post("/predict/crime", dependencies=[Depends(verify_firebase_token)])
    async def predict_crime(...): ...
"""

from __future__ import annotations

from typing import Any

import firebase_admin
from fastapi import HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth_sdk
from firebase_admin import credentials
from loguru import logger

_security = HTTPBearer(auto_error=False)


def init_firebase_app(credentials_path: str) -> None:
    """
    Initialize the Firebase Admin SDK from a service account credentials
    file. Idempotent — safe to call on every service startup.

    Deliberately does NOT raise on failure (e.g. missing/invalid credential
    file, such as in a CI environment with no real Firebase project). If
    initialization fails, `verify_firebase_token` will fail closed with a
    503 for any route that requires it, rather than crashing the whole
    service at startup — `/health` and internal-token-gated routes keep
    working either way.
    """
    if firebase_admin._apps:
        return

    try:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)
        logger.info("✅ Firebase Admin SDK initialized")
    except Exception as exc:
        logger.error(
            f"Firebase Admin SDK initialization failed ({exc}) — routes "
            f"depending on verify_firebase_token will return 503 until a "
            f"valid FIREBASE_CREDENTIALS_PATH is configured."
        )


async def verify_firebase_token(
    credentials: HTTPAuthorizationCredentials | None = Security(_security),
) -> dict[str, Any]:
    """
    FastAPI dependency — verifies the Firebase ID token every mobile/
    dashboard request already sends. Raises 401 if the token is missing,
    invalid, or expired; 503 if the Firebase Admin SDK itself isn't
    configured (distinct from a bad token, so operators can tell the two
    apart in logs/monitoring).

    Returns the decoded token claims (uid, role, etc.) for handlers that
    want them — most routes only need the dependency for its side effect
    (raising on failure) and can ignore the return value.
    """
    if not firebase_admin._apps:
        raise HTTPException(status_code=503, detail="Firebase authentication is not configured")

    if credentials is None:
        raise HTTPException(status_code=401, detail="Missing bearer token")

    try:
        return firebase_auth_sdk.verify_id_token(credentials.credentials)
    except Exception as exc:
        logger.warning(f"Firebase token verification failed: {exc}")
        raise HTTPException(status_code=401, detail="Invalid or expired token") from exc

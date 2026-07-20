"""
SecureCity AI — AI Engine Configuration
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Service
    ENVIRONMENT: str = "development"
    SERVICE_NAME: str = "ai_engine"
    HOST: str = "0.0.0.0"
    PORT: int = 8001

    # Redis
    REDIS_URL: str = "redis://localhost:6379/1"

    # Celery (scheduled ML retraining — see app/celery_app.py). Separate
    # Redis DB indices from REDIS_URL's cache usage above.
    CELERY_BROKER_URL: str = "redis://localhost:6379/3"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/4"

    # MongoDB — internal ML operational data only (model registry,
    # training runs, inference logs, incidents-geo cache). App data
    # (Users, Incidents, ...) lives in Firestore, not here — see
    # backend/docs/mongodb-schema.md.
    MONGODB_URL: str = "mongodb://localhost:27017/securecity_ml"
    MONGODB_DB_NAME: str = "securecity_ml"

    # Models
    MODEL_PATH: str = "/app/models/saved"

    # Security — required, no default (a guessable shipped default would
    # leave /internal/* and /models/retrain open to anyone who reads the
    # source).
    INTERNAL_SERVICE_TOKEN: str
    FIREBASE_CREDENTIALS_PATH: str = "./secrets/firebase_credentials.json"

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000", "https://securecity.example.com"]

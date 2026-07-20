"""
SecureCity AI — CV Engine Configuration
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
    SERVICE_NAME: str = "cv_engine"
    HOST: str = "0.0.0.0"
    PORT: int = 8002

    # Redis
    REDIS_URL: str = "redis://localhost:6379/2"

    # MongoDB — internal ML data only (cv_detection_events); see
    # backend/docs/mongodb-schema.md
    MONGODB_URL: str = "mongodb://localhost:27017/securecity_ml"
    MONGODB_DB_NAME: str = "securecity_ml"

    # Models & CV Settings
    YOLO_MODEL_PATH: str = "yolo11n.pt"  # Can fall back to standard weights
    DETECTION_CONFIDENCE: float = 0.4
    DEVICE: str = "cpu"  # cpu or cuda
    CROWD_ALERT_THRESHOLD: float = 5.0  # persons/m2
    MAX_CONCURRENT_STREAMS: int = 5

    # Fine-tuned weapon/fire-smoke weights (optional — see
    # app/training/train_yolo.py). Absent until a real dataset is trained.
    WEAPON_MODEL_PATH: str | None = None
    FIRE_MODEL_PATH: str | None = None
    TRAINING_OUTPUT_DIR: str = "/app/models/training_runs"

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "./secrets/firebase_credentials.json"

    # Security — required, no default (a guessable shipped default would
    # leave /training/* open to anyone who reads the source).
    INTERNAL_SERVICE_TOKEN: str

    # CORS
    CORS_ORIGINS: list[str] = ["*"]

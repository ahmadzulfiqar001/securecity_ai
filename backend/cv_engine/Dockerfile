# ============================================================
# SecureCity AI — CV Engine Dockerfile (Multi-stage)
#
# Build context is the PARENT `backend/` directory (not
# `backend/cv_engine`), so `backend/shared/` — the Firebase auth module
# shared with ai_engine — is reachable. Build with:
#   docker build -f backend/cv_engine/Dockerfile ./backend
# (docker-compose.yml is already configured this way.)
# ============================================================

# ── Stage 1: Builder ─────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# System deps for building OpenCV/EasyOCR/Ultralytics
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libgomp1 \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy and install dependencies
COPY cv_engine/requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Production ──────────────────────────────────────
FROM python:3.12-slim AS production

LABEL maintainer="SecureCity AI Team"
LABEL service="cv_engine"
LABEL version="1.0.0"

# Runtime deps: libgl1/libglib2.0-0 for OpenCV & EasyOCR, ffmpeg for RTSP
# stream decoding, libsm6/libxext6 for headless X11 stubs some OpenCV
# builds still probe for.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN groupadd -r securecity && useradd -r -g securecity -u 1001 securecity

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code — cv_engine's own app/, plus the shared package
# both services depend on for Firebase token verification.
COPY --chown=securecity:securecity cv_engine/app/ ./app/
COPY --chown=securecity:securecity shared/ ./shared/

# Create model/training directories
RUN mkdir -p /app/models/training_runs && chown -R securecity:securecity /app/models

USER securecity

EXPOSE 8002

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

# --workers 1 is REQUIRED, not just a default: TrackHistoryStore (app/core/
# track_history.py) and StreamManager (app/streams/stream_manager.py) hold
# in-process Python state with no cross-worker coordination. Running more
# than one worker (or more than one replica behind a load balancer) would
# silently split each camera's frames across processes with inconsistent
# tracking/stream state. Do not raise this without first moving that state
# into Redis — see both classes' docstrings.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002", "--workers", "1", "--log-level", "info"]

# ============================================================
# SecureCity AI — AI Engine Dockerfile (Multi-stage)
#
# Build context is the PARENT `backend/` directory (not
# `backend/ai_engine`), so `backend/shared/` — the Firebase auth module
# shared with cv_engine — is reachable. Build with:
#   docker build -f backend/ai_engine/Dockerfile ./backend
# (docker-compose.yml is already configured this way.)
# ============================================================

# ── Stage 1: Builder ─────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# System deps for building ML libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libgomp1 \
    libgdal-dev \
    gdal-bin \
    libproj-dev \
    libgeos-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install dependencies
COPY ai_engine/requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Production ──────────────────────────────────────
FROM python:3.12-slim AS production

LABEL maintainer="SecureCity AI Team"
LABEL service="ai_engine"
LABEL version="1.0.0"

# Runtime deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libgdal32 \
    libproj25 \
    libgeos3.11.1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN groupadd -r securecity && useradd -r -g securecity -u 1001 securecity

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code — ai_engine's own app/, plus the shared package
# both services depend on for Firebase token verification.
COPY --chown=securecity:securecity ai_engine/app/ ./app/
COPY --chown=securecity:securecity shared/ ./shared/

# Create model directory
RUN mkdir -p /app/models/saved && chown -R securecity:securecity /app/models

USER securecity

EXPOSE 8001

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

HEALTHCHECK --interval=30s --timeout=15s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# --workers 1: current default, not a hard requirement — the loaded
# models (crime_predictor, safety_scorer, etc.) are read-only after
# startup, so unlike cv_engine (see its Dockerfile) ai_engine has no
# known in-memory state that would break under multiple workers. Raise
# this only alongside real capacity planning (memory budget per worker,
# since each loads its own copy of every model).
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--workers", "1", "--log-level", "info"]

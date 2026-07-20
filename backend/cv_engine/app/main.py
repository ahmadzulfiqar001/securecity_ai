"""
SecureCity AI — CV Engine FastAPI Application
Computer Vision microservice for real-time threat detection.
"""

from __future__ import annotations

import asyncio
import uuid
from contextlib import asynccontextmanager
from typing import Any

import redis.asyncio as aioredis
from fastapi import (
    FastAPI, HTTPException, UploadFile, File, WebSocket,
    WebSocketDisconnect, BackgroundTasks, Depends, Security
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
from loguru import logger
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
import numpy as np

from app.detectors.yolo_detector import YOLODetector
from app.detectors.crowd_detector import CrowdDensityDetector
from app.detectors.fire_smoke_detector import FireSmokeDetector
from app.detectors.weapon_detector import WeaponDetector
from app.detectors.behavior_detector import BehaviorAnalyzer
from app.detectors.accident_detector import RoadAccidentDetector
from app.detectors.license_plate_detector import LicensePlateDetector
from app.core.track_history import TrackHistoryStore
from app.streams.stream_manager import StreamManager
from app.services.analysis_service import DetectorSuite, run_full_analysis, has_security_relevant_finding, threat_classes_for
from app.training.dataset_spec import DatasetValidationError
from app.training.train_yolo import TrainingError, fine_tune_yolo
from app.training.dataset_spec import WEAPON_CLASSES, FIRE_SMOKE_CLASSES
from app.core import database as db_module
from app.schemas import (
    StreamConfig, CameraConfig, DetectionEvent,
    AnalysisResult, StreamInfo, HealthResponse,
    CvModelStatusResponse, TrainingTriggerRequest,
)
from app.config import Settings
from shared.firebase_auth import init_firebase_app, verify_firebase_token

# ─────────────────────────────────────────────────────────────
settings = Settings()

# ─────────────────────────────────────────────────────────────
# Prometheus Metrics
# ─────────────────────────────────────────────────────────────
FRAMES_PROCESSED = Counter("securecity_cv_frames_processed_total", "Total frames processed", ["camera_id"])
DETECTIONS_MADE = Counter("securecity_cv_detections_total", "Total detections", ["detector_type", "class_name"])
ANALYSIS_LATENCY = Histogram(
    "securecity_cv_analysis_duration_seconds",
    "Frame analysis latency",
    ["detector"],
    buckets=[0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)
ACTIVE_STREAMS = Gauge("securecity_cv_active_streams", "Active RTSP streams")

# ─────────────────────────────────────────────────────────────
# App State
# ─────────────────────────────────────────────────────────────
yolo_detector: YOLODetector | None = None
crowd_detector: CrowdDensityDetector | None = None
fire_smoke_detector: FireSmokeDetector | None = None
weapon_detector: WeaponDetector | None = None
behavior_analyzer: BehaviorAnalyzer | None = None
accident_detector: RoadAccidentDetector | None = None
plate_detector: LicensePlateDetector | None = None
track_history: TrackHistoryStore | None = None
detector_suite: DetectorSuite | None = None
stream_manager: StreamManager | None = None
redis_client: aioredis.Redis | None = None

# WebSocket connection manager
active_ws_connections: dict[str, set[WebSocket]] = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    global yolo_detector, crowd_detector, fire_smoke_detector, weapon_detector
    global behavior_analyzer, accident_detector, plate_detector, track_history
    global detector_suite, stream_manager, redis_client

    logger.info("🚀 SecureCity CV Engine starting up...")

    # Firebase Admin SDK (verifies the ID tokens mobile/dashboard already
    # send on every request) — degrades to 503 on gated routes rather than
    # crashing startup if no valid credentials file is configured.
    init_firebase_app(settings.FIREBASE_CREDENTIALS_PATH)

    # Connect Redis
    redis_client = aioredis.from_url(
        settings.REDIS_URL, encoding="utf-8", decode_responses=False, max_connections=10
    )
    await redis_client.ping()
    logger.info("✅ Redis connected")

    # Connect MongoDB (internal ML data only — see backend/docs/mongodb-schema.md)
    await db_module.connect_db(settings)

    # Load detectors
    logger.info("Loading YOLO detector...")
    yolo_detector = YOLODetector(
        model_path=settings.YOLO_MODEL_PATH,
        confidence_threshold=settings.DETECTION_CONFIDENCE,
        device=settings.DEVICE,
    )

    crowd_detector = CrowdDensityDetector(alert_threshold=settings.CROWD_ALERT_THRESHOLD)
    fire_smoke_detector = FireSmokeDetector(confidence_threshold=0.6, device=settings.DEVICE)
    weapon_detector = WeaponDetector(weapon_model_path=settings.WEAPON_MODEL_PATH, device=settings.DEVICE)
    track_history = TrackHistoryStore()
    behavior_analyzer = BehaviorAnalyzer(track_history=track_history)
    accident_detector = RoadAccidentDetector(track_history=track_history)
    plate_detector = LicensePlateDetector(device=settings.DEVICE)

    detector_suite = DetectorSuite(
        yolo=yolo_detector,
        crowd=crowd_detector,
        fire_smoke=fire_smoke_detector,
        weapon=weapon_detector,
        behavior=behavior_analyzer,
        accident=accident_detector,
    )

    stream_manager = StreamManager(
        detectors=detector_suite,
        redis_client=redis_client,
        ws_connections=active_ws_connections,
        max_streams=settings.MAX_CONCURRENT_STREAMS,
    )

    logger.info("✅ All CV detectors loaded")
    yield

    logger.info("🛑 CV Engine shutting down...")
    if stream_manager:
        await stream_manager.stop_all()
    if redis_client:
        await redis_client.aclose()
    await db_module.close_db()
    logger.info("✅ CV Engine cleanup complete")


# ─────────────────────────────────────────────────────────────
# FastAPI App
# ─────────────────────────────────────────────────────────────
app = FastAPI(
    title="SecureCity CV Engine",
    description="Computer Vision microservice for real-time threat detection and analysis.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Security
security = HTTPBearer(auto_error=False)


async def verify_internal_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> dict[str, Any]:
    """Verify internal service-to-service token (same pattern as ai_engine)."""
    if credentials is None or credentials.credentials != settings.INTERNAL_SERVICE_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid service token")
    return {"authenticated": True}


# ─────────────────────────────────────────────────────────────
# Dependencies
# ─────────────────────────────────────────────────────────────
async def get_detector_suite() -> DetectorSuite:
    if detector_suite is None:
        raise HTTPException(status_code=503, detail="Detector suite not loaded")
    return detector_suite


async def get_stream_manager() -> StreamManager:
    if stream_manager is None:
        raise HTTPException(status_code=503, detail="Stream manager not available")
    return stream_manager


# ─────────────────────────────────────────────────────────────
# Health
# ─────────────────────────────────────────────────────────────
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health() -> HealthResponse:
    checks = {
        "yolo_detector": yolo_detector is not None,
        "crowd_detector": crowd_detector is not None,
        "fire_smoke_detector": fire_smoke_detector is not None,
        "weapon_detector": weapon_detector is not None,
        "behavior_analyzer": behavior_analyzer is not None,
        "accident_detector": accident_detector is not None,
        "plate_detector": plate_detector is not None,
        "stream_manager": stream_manager is not None,
    }
    try:
        await redis_client.ping()
        checks["redis"] = True
    except Exception:
        checks["redis"] = False

    return HealthResponse(
        status="healthy" if all(checks.values()) else "degraded",
        service="cv_engine",
        version="1.0.0",
        checks=checks,
    )


# ─────────────────────────────────────────────────────────────
# Image Analysis
# ─────────────────────────────────────────────────────────────
@app.post(
    "/analyze/image",
    response_model=AnalysisResult,
    tags=["Analysis"],
    dependencies=[Depends(verify_firebase_token)],
)
async def analyze_image(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(..., description="Image frame to analyze (JPEG/PNG)"),
    camera_id: str = "unknown",
    run_all_detectors: bool = True,
    detectors: DetectorSuite = Depends(get_detector_suite),
) -> AnalysisResult:
    """
    Analyze an uploaded image frame for weapons, fire/smoke, crowds,
    vehicles, road accidents, and suspicious behavior — the same full
    detector suite live RTSP streams run (see app/services/analysis_service.py).
    """
    import time
    import cv2

    content = await file.read()
    img_array = np.frombuffer(content, dtype=np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    if frame is None:
        raise HTTPException(status_code=400, detail="Invalid image file")

    start = time.monotonic()

    analysis = run_full_analysis(frame, camera_id, detectors, run_all_detectors=run_all_detectors)

    for det in analysis["detections"]:
        DETECTIONS_MADE.labels(detector_type="yolo", class_name=det["class_name"]).inc()
    if analysis["fire_smoke_analysis"] and analysis["fire_smoke_analysis"]["detected"]:
        DETECTIONS_MADE.labels(detector_type="fire_smoke", class_name="fire_smoke").inc()
    if analysis["weapon_analysis"] and analysis["weapon_analysis"]["weapon_detected"]:
        DETECTIONS_MADE.labels(detector_type="weapon", class_name="weapon").inc()
    if analysis["accident_analysis"] and analysis["accident_analysis"]["accident_suspected"]:
        DETECTIONS_MADE.labels(detector_type="accident", class_name="road_accident").inc()

    elapsed = (time.monotonic() - start) * 1000
    FRAMES_PROCESSED.labels(camera_id=camera_id).inc()
    ANALYSIS_LATENCY.labels(detector="image").observe(elapsed / 1000)

    frame_id = str(uuid.uuid4())

    # Durably log this frame's detections only when something security-
    # relevant was found across ANY detector — every analyzed frame going
    # to MongoDB would be enormous write volume for no analytical benefit
    # (Prometheus already counts every frame via FRAMES_PROCESSED above).
    if has_security_relevant_finding(analysis):
        background_tasks.add_task(
            db_module.log_cv_detection_event,
            camera_id=camera_id,
            frame_id=frame_id,
            detections=analysis["detections"],
            threat_classes=threat_classes_for(analysis),
            max_confidence=max((d["confidence"] for d in analysis["detections"]), default=0.0),
            processing_time_ms=round(elapsed, 2),
        )

    return AnalysisResult(
        camera_id=camera_id,
        frame_id=frame_id,
        detections=analysis["detections"],
        crowd_analysis=analysis["crowd_analysis"],
        fire_smoke_analysis=analysis["fire_smoke_analysis"],
        weapon_analysis=analysis["weapon_analysis"],
        behavior_analysis=analysis["behavior_analysis"],
        accident_analysis=analysis["accident_analysis"],
        processing_time_ms=round(elapsed, 2),
        timestamp=__import__("datetime").datetime.utcnow().isoformat(),
    )


# ─────────────────────────────────────────────────────────────
# Stream Registration
# ─────────────────────────────────────────────────────────────
@app.post("/analyze/stream", tags=["Streams"], dependencies=[Depends(verify_firebase_token)])
async def register_stream(
    config: StreamConfig,
    background_tasks: BackgroundTasks,
    manager: StreamManager = Depends(get_stream_manager),
) -> dict[str, str]:
    """Register an RTSP stream for continuous analysis."""
    stream_id = await manager.start_stream(config)
    ACTIVE_STREAMS.set(manager.active_count)
    return {
        "stream_id": stream_id,
        "status": "started",
        "rtsp_url": config.rtsp_url,
        "message": "Stream analysis started",
    }


@app.get("/streams/", tags=["Streams"], dependencies=[Depends(verify_firebase_token)])
async def list_streams(manager: StreamManager = Depends(get_stream_manager)) -> list[StreamInfo]:
    """List all active RTSP streams."""
    return manager.list_streams()


@app.delete("/streams/{stream_id}", tags=["Streams"], dependencies=[Depends(verify_firebase_token)])
async def stop_stream(
    stream_id: str,
    manager: StreamManager = Depends(get_stream_manager),
) -> dict[str, str]:
    """Stop analysis of a registered RTSP stream."""
    success = await manager.stop_stream(stream_id)
    if not success:
        raise HTTPException(status_code=404, detail=f"Stream {stream_id} not found")
    ACTIVE_STREAMS.set(manager.active_count)
    return {"stream_id": stream_id, "status": "stopped"}


# ─────────────────────────────────────────────────────────────
# Detection Log
# ─────────────────────────────────────────────────────────────
@app.get("/detections/", tags=["Detections"], dependencies=[Depends(verify_firebase_token)])
async def get_recent_detections(
    camera_id: str | None = None,
    limit: int = 50,
    offset: int = 0,
) -> list[dict[str, Any]]:
    """Get recent detection events from Redis pub/sub log."""
    import json
    pattern = f"detections:{camera_id}:*" if camera_id else "detections:*:*"
    # scan_iter (non-blocking cursor-based SCAN) instead of KEYS, which
    # blocks the single-threaded Redis event loop for O(N) over the whole
    # keyspace — same matched key set, just retrieved without stalling
    # every other Redis client while it runs.
    keys = [key async for key in redis_client.scan_iter(match=pattern)]
    keys = sorted(keys, reverse=True)[offset: offset + limit]

    results = []
    for key in keys:
        data = await redis_client.get(key)
        if data:
            try:
                results.append(json.loads(data))
            except Exception:
                pass
    return results


# ─────────────────────────────────────────────────────────────
# Camera Registration
# ─────────────────────────────────────────────────────────────
@app.post("/cameras/", tags=["Cameras"], dependencies=[Depends(verify_firebase_token)])
async def register_camera(config: CameraConfig) -> dict[str, Any]:
    """Register a new camera in the system."""
    camera_id = str(uuid.uuid4())
    import json
    camera_data = {
        "camera_id": camera_id,
        "name": config.name,
        "rtsp_url": config.rtsp_url,
        "location": config.location,
        "zone_id": config.zone_id,
        "registered_at": __import__("datetime").datetime.utcnow().isoformat(),
        "status": "registered",
    }
    await redis_client.setex(
        f"camera:{camera_id}",
        86400 * 30,
        json.dumps(camera_data),
    )
    return camera_data


# ─────────────────────────────────────────────────────────────
# WebSocket — Real-time Detection Events
# ─────────────────────────────────────────────────────────────
@app.websocket("/ws/stream/{camera_id}")
async def websocket_stream(
    websocket: WebSocket,
    camera_id: str,
) -> None:
    """
    WebSocket endpoint for real-time detection events from a specific camera.
    Clients receive JSON detection events as they happen.
    """
    await websocket.accept()

    if camera_id not in active_ws_connections:
        active_ws_connections[camera_id] = set()
    active_ws_connections[camera_id].add(websocket)
    logger.info(f"WebSocket client connected for camera {camera_id}")

    try:
        await websocket.send_json({
            "type": "connected",
            "camera_id": camera_id,
            "message": "Real-time detection stream active",
        })

        # Keep connection alive — events are pushed by stream_manager
        while True:
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=30.0)
                if data == "ping":
                    await websocket.send_json({"type": "pong"})
            except asyncio.TimeoutError:
                # Send keepalive
                await websocket.send_json({"type": "keepalive"})

    except WebSocketDisconnect:
        logger.info(f"WebSocket client disconnected from camera {camera_id}")
    finally:
        if camera_id in active_ws_connections:
            active_ws_connections[camera_id].discard(websocket)
            if not active_ws_connections[camera_id]:
                del active_ws_connections[camera_id]


# ─────────────────────────────────────────────────────────────
# Model Status
# ─────────────────────────────────────────────────────────────
@app.get(
    "/models/status",
    response_model=CvModelStatusResponse,
    tags=["Models"],
    summary="Get CV detector health and configuration status",
    dependencies=[Depends(verify_firebase_token)],
)
async def get_model_status(
    detectors: DetectorSuite = Depends(get_detector_suite),
) -> CvModelStatusResponse:
    """Reports each detector's real load state — including whether the
    optional firearm/fire custom models are actually loaded, so it's
    obvious which capabilities are classical-only vs. custom-model-backed."""
    return CvModelStatusResponse(
        yolo_detector=detectors.yolo.get_stats(),
        crowd_detector=detectors.crowd.get_stats(),
        fire_smoke_detector=detectors.fire_smoke.get_status(),
        weapon_detector=detectors.weapon.get_status(),
        behavior_analyzer=detectors.behavior.get_status(),
        accident_detector=detectors.accident.get_status(),
        plate_detector=plate_detector.get_stats() if plate_detector else {},
        active_detectors=6,
    )


# ─────────────────────────────────────────────────────────────
# Training Triggers (Admin) — kick off fine-tuning once a real dataset
# is supplied. See app/training/dataset_spec.py for the expected layout.
# ─────────────────────────────────────────────────────────────
async def _run_training(
    dataset_root: str,
    classes: list[str],
    run_name: str,
    epochs: int,
    imgsz: int,
    batch: int,
) -> None:
    try:
        result = fine_tune_yolo(
            dataset_root=dataset_root,
            classes=classes,
            output_dir=settings.TRAINING_OUTPUT_DIR,
            run_name=run_name,
            device=settings.DEVICE,
            epochs=epochs,
            imgsz=imgsz,
            batch=batch,
        )
        logger.info(f"✅ Training '{run_name}' finished: {result}")
    except (DatasetValidationError, TrainingError) as exc:
        logger.error(f"❌ Training '{run_name}' failed: {exc}")


@app.post(
    "/training/weapon",
    tags=["Training"],
    summary="Trigger firearm-detection fine-tuning on a supplied dataset (admin only)",
    dependencies=[Depends(verify_internal_token)],
)
async def trigger_weapon_training(
    request: TrainingTriggerRequest,
    background_tasks: BackgroundTasks,
) -> dict[str, str]:
    background_tasks.add_task(
        _run_training,
        dataset_root=request.dataset_root,
        classes=WEAPON_CLASSES,
        run_name="weapon",
        epochs=request.epochs,
        imgsz=request.imgsz,
        batch=request.batch,
    )
    return {"status": "queued", "run_name": "weapon", "dataset_root": request.dataset_root}


@app.post(
    "/training/fire-smoke",
    tags=["Training"],
    summary="Trigger fire/smoke-detection fine-tuning on a supplied dataset (admin only)",
    dependencies=[Depends(verify_internal_token)],
)
async def trigger_fire_smoke_training(
    request: TrainingTriggerRequest,
    background_tasks: BackgroundTasks,
) -> dict[str, str]:
    background_tasks.add_task(
        _run_training,
        dataset_root=request.dataset_root,
        classes=FIRE_SMOKE_CLASSES,
        run_name="fire_smoke",
        epochs=request.epochs,
        imgsz=request.imgsz,
        batch=request.batch,
    )
    return {"status": "queued", "run_name": "fire_smoke", "dataset_root": request.dataset_root}


# ─────────────────────────────────────────────────────────────
# Exception Handler
# ─────────────────────────────────────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request, exc: Exception) -> JSONResponse:
    logger.error(f"CV Engine unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8002, reload=False, workers=1)

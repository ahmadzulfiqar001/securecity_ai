"""
SecureCity AI — Stream Manager
Manages background processing of camera RTSP streams.
"""

from __future__ import annotations

import asyncio
import datetime
import json
import time
from typing import Any
import cv2
from loguru import logger
import redis.asyncio as aioredis
from fastapi import WebSocket

from app.schemas import StreamConfig, StreamInfo
from app.services.analysis_service import DetectorSuite, run_full_analysis


class StreamProcessor:
    """
    Processes a single camera stream in a background task.
    Reads frames, runs the full detector suite (not just raw YOLO — see
    app/services/analysis_service.py), and publishes results to Redis and
    WebSockets.
    """

    def __init__(
        self,
        stream_id: str,
        config: StreamConfig,
        detectors: DetectorSuite,
        redis_client: aioredis.Redis,
        ws_connections: dict[str, set[WebSocket]],
    ) -> None:
        self.stream_id = stream_id
        self.config = config
        self.detectors = detectors
        self.redis = redis_client
        self.ws_connections = ws_connections
        self.running = False
        self.fps = 0.0
        self.started_at = datetime.datetime.utcnow().isoformat()
        self._task: asyncio.Task | None = None

    def start(self) -> None:
        self.running = True
        self._task = asyncio.create_task(self._run())
        logger.info(f"Started stream processor task for camera {self.config.camera_id}")

    async def stop(self) -> None:
        self.running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info(f"Stopped stream processor task for camera {self.config.camera_id}")

    async def _run(self) -> None:
        camera_id = self.config.camera_id
        rtsp_url = self.config.rtsp_url

        # For development, we support simulating frames if RTSP is not reachable
        is_simulation = rtsp_url.lower() == "simulate" or not rtsp_url.startswith("rtsp://")
        
        cap = None
        if not is_simulation:
            cap = cv2.VideoCapture(rtsp_url)
            if not cap.isOpened():
                logger.warning(f"Could not open RTSP stream: {rtsp_url}. Switching to simulation mode.")
                is_simulation = True

        frame_count = 0
        start_time = time.time()

        try:
            while self.running:
                frame = None
                if is_simulation:
                    # Create a simulated frame (empty black image or noise)
                    frame = np.zeros((480, 640, 3), dtype=np.uint8)
                    cv2.putText(
                        frame,
                        f"Simulated Feed: {camera_id} - FPS: {self.fps:.1f}",
                        (30, 50),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (0, 255, 0),
                        2,
                    )
                    # Simulate some person walking
                    # Bounding box simulation
                    t = time.time()
                    x = int(320 + 150 * np.sin(t))
                    y = int(240 + 50 * np.cos(t))
                    cv2.rectangle(frame, (x-20, y-50), (x+20, y+50), (0, 0, 255), 2)
                    cv2.putText(frame, "person", (x-20, y-60), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)
                    await asyncio.sleep(0.033)  # ~30 FPS
                else:
                    ret, frame = cap.read()
                    if not ret:
                        logger.warning(f"Failed to read frame from stream {camera_id}. Retrying...")
                        await asyncio.sleep(1.0)
                        continue

                frame_count += 1
                elapsed = time.time() - start_time
                if elapsed >= 1.0:
                    self.fps = frame_count / elapsed
                    frame_count = 0
                    start_time = time.time()

                # Process every 5th frame for inference to save CPU/GPU resources
                if frame_count % 5 == 0:
                    if is_simulation:
                        # In simulation, fake a single person detection — no
                        # real camera to run the full detector suite against.
                        x = int(320 + 150 * np.sin(time.time()))
                        y = int(240 + 50 * np.cos(time.time()))
                        analysis = {
                            "detections": [{
                                "class_name": "person",
                                "confidence": 0.85,
                                "bbox": [float(x-20), float(y-50), float(x+20), float(y+50)],
                                "center": [float(x), float(y)]
                            }],
                            "crowd_analysis": None,
                            "fire_smoke_analysis": None,
                            "weapon_analysis": None,
                            "behavior_analysis": None,
                            "accident_analysis": None,
                        }
                    else:
                        analysis = run_full_analysis(frame, camera_id, self.detectors)

                    # Build detection event payload
                    event = {
                        "camera_id": camera_id,
                        "timestamp": datetime.datetime.utcnow().isoformat(),
                        "fps": round(self.fps, 1),
                        **analysis,
                    }

                    event_json = json.dumps(event)

                    # 1. Publish to Redis channel for live subscribers
                    await self.redis.publish(f"channel:detections:{camera_id}", event_json)

                    # 2. Store in Redis with TTL for logging queries
                    key = f"detections:{camera_id}:{int(time.time() * 1000)}"
                    await self.redis.setex(key, 3600, event_json)  # Expire in 1 hour

                    # 3. Broadcast to WebSocket connections
                    websockets = self.ws_connections.get(camera_id, set())
                    if websockets:
                        ws_payload = {"type": "detections", "data": event}
                        # We send to all active websockets, handling disconnections gracefully
                        disconnected = set()
                        for ws in websockets:
                            try:
                                await ws.send_json(ws_payload)
                            except Exception:
                                disconnected.add(ws)
                        
                        for ws in disconnected:
                            websockets.discard(ws)

        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error(f"Error in stream processor for camera {camera_id}: {e}")
        finally:
            if cap:
                cap.release()


import numpy as np


class StreamManager:
    """
    Manages running RTSP streams and their processors.

    SCALING BOUNDARY: active stream handles/tasks live in this process's
    memory (self._streams et al.), not in Redis or any shared store.
    Running cv_engine with more than one uvicorn worker or replica means
    each has its own independent, inconsistent view of "active streams" —
    a stream registered on one worker won't be visible (or stoppable) via
    a request that lands on another. Keep cv_engine single-worker/
    single-replica until this is moved to shared state; see the
    Dockerfile CMD's `--workers 1`.
    """

    def __init__(
        self,
        detectors: DetectorSuite,
        redis_client: aioredis.Redis,
        ws_connections: dict[str, set[WebSocket]],
        max_streams: int = 5,
    ) -> None:
        self.detectors = detectors
        self.redis = redis_client
        self.ws_connections = ws_connections
        self.max_streams = max_streams
        self.processors: dict[str, StreamProcessor] = {}

    @property
    def active_count(self) -> int:
        return len(self.processors)

    async def start_stream(self, config: StreamConfig) -> str:
        """Start background processing for a stream."""
        camera_id = config.camera_id

        # If already running, stop the old one first
        if camera_id in self.processors:
            await self.stop_stream(camera_id)

        if len(self.processors) >= self.max_streams:
            raise ValueError(f"Maximum concurrent streams ({self.max_streams}) reached.")

        processor = StreamProcessor(
            stream_id=camera_id,
            config=config,
            detectors=self.detectors,
            redis_client=self.redis,
            ws_connections=self.ws_connections,
        )
        processor.start()
        self.processors[camera_id] = processor
        return camera_id

    async def stop_stream(self, stream_id: str) -> bool:
        """Stop background processing for a stream."""
        processor = self.processors.pop(stream_id, None)
        if processor:
            await processor.stop()
            return True
        return False

    async def stop_all(self) -> None:
        """Stop all streams."""
        for processor in list(self.processors.values()):
            await processor.stop()
        self.processors.clear()

    def list_streams(self) -> list[StreamInfo]:
        """List status of all active streams."""
        return [
            StreamInfo(
                stream_id=p.stream_id,
                rtsp_url=p.config.rtsp_url,
                camera_id=p.config.camera_id,
                status="running" if p.running else "stopped",
                fps=round(p.fps, 1),
                started_at=p.started_at,
            )
            for p in self.processors.values()
        ]

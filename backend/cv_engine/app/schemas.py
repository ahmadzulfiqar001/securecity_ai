"""
SecureCity AI — CV Engine Schemas
"""

from pydantic import BaseModel, Field
from typing import Any, List, Dict, Optional


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    checks: Dict[str, bool]


class DetectionEvent(BaseModel):
    class_name: str
    confidence: float
    bbox: List[float]  # [x1, y1, x2, y2]
    center: Optional[List[float]] = None
    attributes: Optional[Dict[str, Any]] = None


class CrowdAnalysisResult(BaseModel):
    count: int
    density: float
    density_unit: str
    alert_level: str
    is_alert: bool
    centroid: Optional[List[float]] = None
    crowd_bbox: Optional[List[float]] = None
    thresholds: Dict[str, float]


class FireSmokeAnalysisResult(BaseModel):
    detected: bool
    confidence: float
    detections: List[Dict[str, Any]]


class BehaviorAnalysisResult(BaseModel):
    actions: List[str]
    alert_triggered: bool
    details: Dict[str, Any]


class WeaponAnalysisResult(BaseModel):
    weapon_detected: bool
    weapons: List[Dict[str, Any]]
    bladed_blunt_count: int
    firearm_count: int
    firearm_model_loaded: bool


class AccidentAnalysisResult(BaseModel):
    accident_suspected: bool
    severity: str
    incidents: List[Dict[str, Any]]
    involved_track_ids: List[int]


class AnalysisResult(BaseModel):
    camera_id: str
    frame_id: str
    detections: List[Dict[str, Any]]
    crowd_analysis: Optional[CrowdAnalysisResult] = None
    fire_smoke_analysis: Optional[Dict[str, Any]] = None
    weapon_analysis: Optional[Dict[str, Any]] = None
    behavior_analysis: Optional[Dict[str, Any]] = None
    accident_analysis: Optional[Dict[str, Any]] = None
    processing_time_ms: float
    timestamp: str


class StreamConfig(BaseModel):
    camera_id: str
    rtsp_url: str
    zone_id: str
    run_all_detectors: Optional[bool] = True


class CameraConfig(BaseModel):
    name: str
    rtsp_url: str
    location: List[float]  # [lng, lat]
    zone_id: str


class StreamInfo(BaseModel):
    stream_id: str
    rtsp_url: str
    camera_id: str
    status: str
    fps: float
    started_at: str


class CvModelStatusResponse(BaseModel):
    yolo_detector: Dict[str, Any]
    crowd_detector: Dict[str, Any]
    fire_smoke_detector: Dict[str, Any]
    weapon_detector: Dict[str, Any]
    behavior_analyzer: Dict[str, Any]
    accident_detector: Dict[str, Any]
    plate_detector: Dict[str, Any]
    active_detectors: int


class TrainingTriggerRequest(BaseModel):
    dataset_root: str = Field(..., description="Path to a YOLO-format dataset — see app/training/dataset_spec.py")
    epochs: int = Field(default=50, ge=1, le=1000)
    imgsz: int = Field(default=640, ge=64, le=2560)
    batch: int = Field(default=16, ge=1, le=256)

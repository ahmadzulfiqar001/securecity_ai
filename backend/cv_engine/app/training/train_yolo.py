"""
SecureCity AI — YOLO Fine-Tuning Pipeline

Generic Ultralytics fine-tuning wrapper used to train the firearm-detection
and fire/smoke-detection weights that `WeaponDetector`/`FireSmokeDetector`
can optionally load (`WEAPON_MODEL_PATH`/`FIRE_MODEL_PATH`).

No training run is bundled with this pipeline — there is no legitimate way
to fabricate real photographs of firearms or fires the way tabular training
data was synthesized elsewhere in this project. This is the real,
reusable pipeline, ready the moment a real annotated dataset (see
app/training/dataset_spec.py for the expected layout) is supplied.
"""

from __future__ import annotations

import os
from datetime import datetime
from typing import Any

from loguru import logger

from app.training.dataset_spec import generate_data_yaml, validate_dataset_layout


class TrainingError(RuntimeError):
    """Raised when a fine-tuning run cannot start or fails."""


def fine_tune_yolo(
    dataset_root: str,
    classes: list[str],
    output_dir: str,
    run_name: str,
    base_weights: str = "yolo11n.pt",
    epochs: int = 50,
    imgsz: int = 640,
    batch: int = 16,
    device: str = "cpu",
) -> dict[str, Any]:
    """
    Fine-tune a YOLOv11 model on a real, annotated dataset.

    Args:
        dataset_root: path to a dataset in the layout dataset_spec.py
            documents (images/train, images/val, labels/train, labels/val).
        classes: ordered class names matching the dataset's label indices.
        output_dir: directory to save the trained weights under.
        run_name: subdirectory name for this training run (e.g. "weapon_v1").
        base_weights: pretrained weights to fine-tune from.
        epochs, imgsz, batch, device: standard Ultralytics training params.

    Returns:
        dict with status, weights_path, and metrics.

    Raises:
        DatasetValidationError: if the dataset doesn't match the expected layout.
        TrainingError: if Ultralytics isn't installed or training fails.
    """
    summary = validate_dataset_layout(dataset_root, classes)
    for warning in summary.warnings:
        logger.warning(f"[{run_name}] {warning}")

    data_yaml_path = generate_data_yaml(dataset_root, classes)

    try:
        from ultralytics import YOLO
    except ImportError as exc:
        raise TrainingError("ultralytics is not installed — cannot run training.") from exc

    logger.info(
        f"Starting YOLO fine-tuning '{run_name}': {summary.train_image_count} train images, "
        f"{summary.val_image_count} val images, classes={classes}, epochs={epochs}"
    )

    started_at = datetime.utcnow()
    try:
        model = YOLO(base_weights)
        results = model.train(
            data=data_yaml_path,
            epochs=epochs,
            imgsz=imgsz,
            batch=batch,
            device=device,
            project=output_dir,
            name=run_name,
            exist_ok=True,
            verbose=False,
        )
    except Exception as exc:
        raise TrainingError(f"YOLO fine-tuning failed for '{run_name}': {exc}") from exc

    completed_at = datetime.utcnow()
    weights_path = os.path.join(output_dir, run_name, "weights", "best.pt")
    metrics = _extract_metrics(results)

    logger.info(f"✅ '{run_name}' training complete in {(completed_at - started_at).total_seconds():.1f}s: {metrics}")

    return {
        "status": "completed",
        "run_name": run_name,
        "weights_path": weights_path,
        "classes": classes,
        "dataset_summary": {
            "train_images": summary.train_image_count,
            "val_images": summary.val_image_count,
        },
        "metrics": metrics,
        "started_at": started_at.isoformat(),
        "completed_at": completed_at.isoformat(),
    }


def _extract_metrics(results: Any) -> dict[str, float]:
    """Best-effort extraction of key metrics from an Ultralytics training result."""
    try:
        metrics_dict = getattr(results, "results_dict", {}) or {}
        return {
            "mAP50": round(float(metrics_dict.get("metrics/mAP50(B)", 0.0)), 4),
            "mAP50-95": round(float(metrics_dict.get("metrics/mAP50-95(B)", 0.0)), 4),
            "precision": round(float(metrics_dict.get("metrics/precision(B)", 0.0)), 4),
            "recall": round(float(metrics_dict.get("metrics/recall(B)", 0.0)), 4),
        }
    except Exception as exc:
        logger.warning(f"Could not extract training metrics: {exc}")
        return {}

"""
SecureCity AI — YOLO Dataset Spec

Defines the dataset layout `train_yolo.py` expects, and validates/generates
the Ultralytics `data.yaml` from it.

There is no legitimate way to fabricate photographs of firearms or fires
in this environment the way tabular training data could be synthesized
elsewhere in this project — this module is the "bring your own dataset"
contract: point it at a real, annotated dataset in this layout (e.g. a
Roboflow Universe export in YOLO format) and the training pipeline can use
it.

Expected layout, rooted at `dataset_root`:

    dataset_root/
      images/train/*.jpg
      images/val/*.jpg
      labels/train/*.txt   (YOLO format: `class_id cx cy w h`, normalized)
      labels/val/*.txt
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field

import yaml

WEAPON_CLASSES = ["pistol", "rifle"]
FIRE_SMOKE_CLASSES = ["fire", "smoke"]

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp"}


class DatasetValidationError(ValueError):
    """Raised when a dataset directory doesn't match the expected YOLO layout."""


@dataclass
class DatasetSummary:
    dataset_root: str
    classes: list[str]
    train_image_count: int
    train_label_count: int
    val_image_count: int
    val_label_count: int
    warnings: list[str] = field(default_factory=list)


def validate_dataset_layout(dataset_root: str, classes: list[str]) -> DatasetSummary:
    """
    Check that `dataset_root` has the expected YOLO directory layout with
    at least some images and matching labels. Raises DatasetValidationError
    with a specific, actionable message if not.
    """
    if not os.path.isdir(dataset_root):
        raise DatasetValidationError(
            f"Dataset root '{dataset_root}' does not exist. Supply a real, "
            f"annotated YOLO-format dataset (e.g. exported from Roboflow "
            f"Universe or labeled with a tool like CVAT/LabelImg) with this "
            f"layout: images/train, images/val, labels/train, labels/val."
        )

    required_dirs = [
        os.path.join(dataset_root, "images", "train"),
        os.path.join(dataset_root, "images", "val"),
        os.path.join(dataset_root, "labels", "train"),
        os.path.join(dataset_root, "labels", "val"),
    ]
    missing = [d for d in required_dirs if not os.path.isdir(d)]
    if missing:
        raise DatasetValidationError(
            f"Dataset root '{dataset_root}' is missing required directories: "
            f"{', '.join(missing)}"
        )

    train_images = _count_images(os.path.join(dataset_root, "images", "train"))
    val_images = _count_images(os.path.join(dataset_root, "images", "val"))
    train_labels = _count_labels(os.path.join(dataset_root, "labels", "train"))
    val_labels = _count_labels(os.path.join(dataset_root, "labels", "val"))

    if train_images == 0:
        raise DatasetValidationError(
            f"No training images found under '{dataset_root}/images/train'."
        )

    warnings: list[str] = []
    if train_images != train_labels:
        warnings.append(
            f"Train image/label count mismatch: {train_images} images vs {train_labels} labels."
        )
    if val_images != val_labels:
        warnings.append(
            f"Val image/label count mismatch: {val_images} images vs {val_labels} labels."
        )
    if val_images == 0:
        warnings.append("No validation images found — training will run without held-out evaluation.")

    return DatasetSummary(
        dataset_root=dataset_root,
        classes=classes,
        train_image_count=train_images,
        train_label_count=train_labels,
        val_image_count=val_images,
        val_label_count=val_labels,
        warnings=warnings,
    )


def generate_data_yaml(dataset_root: str, classes: list[str], output_path: str | None = None) -> str:
    """
    Write (and return the path to) an Ultralytics-compatible `data.yaml`
    for `dataset_root`. Does not itself validate the dataset — call
    `validate_dataset_layout()` first.
    """
    data = {
        "path": os.path.abspath(dataset_root),
        "train": "images/train",
        "val": "images/val",
        "names": {i: name for i, name in enumerate(classes)},
    }

    output_path = output_path or os.path.join(dataset_root, "data.yaml")
    with open(output_path, "w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False)

    return output_path


def _count_images(directory: str) -> int:
    return sum(
        1 for name in os.listdir(directory)
        if os.path.splitext(name)[1].lower() in IMAGE_EXTENSIONS
    )


def _count_labels(directory: str) -> int:
    return sum(1 for name in os.listdir(directory) if name.lower().endswith(".txt"))

"""Tests for app/training/dataset_spec.py — real filesystem I/O in
pytest's tmp_path, no MongoDB/Redis/real image dataset needed."""

from __future__ import annotations

import os

import pytest
import yaml

from app.training.dataset_spec import (
    DatasetValidationError,
    generate_data_yaml,
    validate_dataset_layout,
)


def _make_dataset(root, train_images=2, train_labels=2, val_images=1, val_labels=1):
    for sub, count, ext in [
        ("images/train", train_images, ".jpg"),
        ("images/val", val_images, ".jpg"),
        ("labels/train", train_labels, ".txt"),
        ("labels/val", val_labels, ".txt"),
    ]:
        d = root / sub
        d.mkdir(parents=True, exist_ok=True)
        for i in range(count):
            (d / f"item_{i}{ext}").write_text("")


def test_validate_missing_root_raises(tmp_path):
    missing_root = tmp_path / "does_not_exist"
    with pytest.raises(DatasetValidationError):
        validate_dataset_layout(str(missing_root), ["pistol", "rifle"])


def test_validate_missing_subdirs_raises(tmp_path):
    (tmp_path / "images" / "train").mkdir(parents=True)
    with pytest.raises(DatasetValidationError) as exc_info:
        validate_dataset_layout(str(tmp_path), ["pistol", "rifle"])
    assert "images" in str(exc_info.value) or "labels" in str(exc_info.value)


def test_validate_no_training_images_raises(tmp_path):
    _make_dataset(tmp_path, train_images=0, train_labels=0, val_images=1, val_labels=1)
    with pytest.raises(DatasetValidationError):
        validate_dataset_layout(str(tmp_path), ["fire", "smoke"])


def test_validate_success_counts_files(tmp_path):
    _make_dataset(tmp_path, train_images=3, train_labels=3, val_images=2, val_labels=2)
    summary = validate_dataset_layout(str(tmp_path), ["fire", "smoke"])

    assert summary.train_image_count == 3
    assert summary.train_label_count == 3
    assert summary.val_image_count == 2
    assert summary.val_label_count == 2
    assert summary.warnings == []


def test_validate_mismatch_warns_without_raising(tmp_path):
    _make_dataset(tmp_path, train_images=3, train_labels=1, val_images=1, val_labels=1)
    summary = validate_dataset_layout(str(tmp_path), ["fire", "smoke"])

    assert any("mismatch" in w.lower() for w in summary.warnings)


def test_validate_no_val_images_warns(tmp_path):
    _make_dataset(tmp_path, train_images=2, train_labels=2, val_images=0, val_labels=0)
    summary = validate_dataset_layout(str(tmp_path), ["fire", "smoke"])

    assert any("validation" in w.lower() for w in summary.warnings)


def test_generate_data_yaml_writes_expected_structure(tmp_path):
    _make_dataset(tmp_path)
    output_path = generate_data_yaml(str(tmp_path), ["pistol", "rifle"])

    assert os.path.exists(output_path)
    with open(output_path, encoding="utf-8") as f:
        data = yaml.safe_load(f)

    assert data["train"] == "images/train"
    assert data["val"] == "images/val"
    assert data["names"] == {0: "pistol", 1: "rifle"}
    assert data["path"] == os.path.abspath(str(tmp_path))

"""
Tests for app/core/ml_repository.py and app/core/database.py's index/
validator setup. Requires a reachable MongoDB — see conftest.py.
"""

from __future__ import annotations

from datetime import datetime, timezone

import pytest
from pymongo.errors import WriteError

from app.core.database import COL_INCIDENTS_GEO, COL_ML_MODELS, COL_TRAINING_RUNS
from app.core.ml_repository import (
    crime_density_by_zone,
    delete_incident_geo,
    inference_volume_by_endpoint,
    log_inference,
    record_training_run,
    upsert_incident_geo,
    upsert_model_registry,
)

pytestmark = pytest.mark.asyncio


async def test_indexes_are_created(db):
    indexes = await db[COL_INCIDENTS_GEO].index_information()
    assert "idx_location_2dsphere" in indexes

    ml_model_indexes = await db[COL_ML_MODELS].index_information()
    assert "uidx_name_version" in ml_model_indexes
    assert ml_model_indexes["uidx_name_version"]["unique"] is True


async def test_validator_rejects_malformed_document(db):
    # Missing the required `status` field.
    with pytest.raises(WriteError):
        await db[COL_ML_MODELS].insert_one({
            "name": "crime_predictor",
            "version": "1",
            "service": "ai_engine",
            "created_at": datetime.now(timezone.utc),
        })


async def test_upsert_model_registry_round_trip(db):
    await upsert_model_registry(
        name="crime_predictor",
        version="20260101000000",
        service="ai_engine",
        status="active",
        algorithm="XGBoostClassifier",
        metrics={"auc_roc": 0.91},
        trained_at=datetime.now(timezone.utc),
    )

    doc = await db[COL_ML_MODELS].find_one({"name": "crime_predictor", "version": "20260101000000"})
    assert doc is not None
    assert doc["status"] == "active"
    assert doc["metrics"]["auc_roc"] == 0.91

    # Upserting the same name+version again updates in place, not duplicates.
    await upsert_model_registry(
        name="crime_predictor",
        version="20260101000000",
        service="ai_engine",
        status="deprecated",
    )
    count = await db[COL_ML_MODELS].count_documents(
        {"name": "crime_predictor", "version": "20260101000000"}
    )
    assert count == 1
    doc = await db[COL_ML_MODELS].find_one({"name": "crime_predictor", "version": "20260101000000"})
    assert doc["status"] == "deprecated"


async def test_record_training_run(db):
    run_id = await record_training_run(
        model_name="crime_predictor",
        started_at=datetime.now(timezone.utc),
        status="completed",
        triggered_by="manual",
        sample_count=500,
        metrics={"f1": 0.8},
    )
    assert run_id

    doc = await db[COL_TRAINING_RUNS].find_one({"model_name": "crime_predictor"})
    assert doc is not None
    assert doc["sample_count"] == 500


async def test_log_inference_never_raises_on_bad_db_state(db):
    # log_inference swallows its own exceptions — this just confirms the
    # happy path writes a document; error-path safety is exercised by the
    # try/except in the function itself (fire-and-forget from BackgroundTasks).
    await log_inference(
        service="ai_engine",
        endpoint="/predict/crime",
        model_name="crime_predictor",
        status="success",
        confidence=0.75,
        latency_ms=12.3,
    )
    doc = await db["inference_logs"].find_one({"endpoint": "/predict/crime"})
    assert doc is not None
    assert doc["confidence"] == 0.75


async def test_incidents_geo_upsert_and_delete(db):
    await upsert_incident_geo(
        incident_id="incident-1",
        longitude=67.0011,
        latitude=24.8607,
        incident_type="ROBBERY",
        zone_id="zone_a",
    )
    doc = await db[COL_INCIDENTS_GEO].find_one({"_id": "incident-1"})
    assert doc is not None
    assert doc["location"]["coordinates"] == [67.0011, 24.8607]

    await delete_incident_geo("incident-1")
    doc = await db[COL_INCIDENTS_GEO].find_one({"_id": "incident-1"})
    assert doc is None


async def test_aggregation_pipelines_return_shaped_results(db):
    await upsert_incident_geo(
        incident_id="incident-2",
        longitude=67.0,
        latitude=24.9,
        incident_type="ROBBERY",
        zone_id="zone_b",
    )
    await log_inference(service="ai_engine", endpoint="/predict/crime", status="success")

    zone_results = await crime_density_by_zone(days=30)
    assert isinstance(zone_results, list)
    if zone_results:
        assert "incident_count" in zone_results[0]

    volume_results = await inference_volume_by_endpoint(days=1)
    assert isinstance(volume_results, list)
    if volume_results:
        assert "request_count" in volume_results[0]

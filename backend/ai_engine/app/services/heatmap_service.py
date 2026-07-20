"""
SecureCity AI — HeatmapService
KDE-based crime density heatmap generation using scipy gaussian_kde.
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta
from typing import Any

import numpy as np
from loguru import logger
from motor.motor_asyncio import AsyncIOMotorDatabase
from scipy.stats import gaussian_kde

from app.core.database import COL_INCIDENTS_GEO


class HeatmapService:
    """
    KDE (Kernel Density Estimation) based crime density heatmap generator.

    Fetches incident coordinates from the `incidents_geo` MongoDB cache
    (kept current from Firestore's `incidents` — the real source of truth
    — by the syncIncidentGeoCache Cloud Function; see
    backend/docs/mongodb-schema.md) and computes a grid-based density
    estimation, returning a GeoJSON FeatureCollection.
    """

    GRID_RESOLUTION = 50  # Grid points per axis (50x50 = 2500 points)
    COLLECTION_NAME = COL_INCIDENTS_GEO

    def __init__(
        self,
        database: AsyncIOMotorDatabase,
        redis_client: Any,
    ) -> None:
        self._db = database
        self._redis = redis_client

    async def generate_heatmap(
        self,
        days: int = 30,
        incident_type: str | None = None,
        bounds: tuple[float, float, float, float] = (24.8, 25.0, 66.9, 67.2),
    ) -> dict[str, Any]:
        """
        Generate a KDE-based heatmap for a geographic bounding box.

        Args:
            days: Number of past days to include (7, 30, 90, or custom)
            incident_type: Filter by incident type (None = all types)
            bounds: (min_lat, max_lat, min_lon, max_lon)

        Returns:
            GeoJSON FeatureCollection with density values
        """
        min_lat, max_lat, min_lon, max_lon = bounds

        # Fetch incident coordinates from MongoDB
        coordinates = await self._fetch_incident_coordinates(
            days=days,
            incident_type=incident_type,
            bounds=bounds,
        )

        if len(coordinates) < 5:
            # Not enough data for KDE — return empty heatmap
            logger.warning(f"Only {len(coordinates)} incidents found — returning empty heatmap")
            return self._empty_heatmap_response(bounds, days)

        # Build coordinate arrays
        lats = np.array([c["lat"] for c in coordinates])
        lons = np.array([c["lon"] for c in coordinates])

        # KDE estimation
        grid_lats, grid_lons, densities = self._compute_kde(
            lats=lats,
            lons=lons,
            min_lat=min_lat,
            max_lat=max_lat,
            min_lon=min_lon,
            max_lon=max_lon,
        )

        # Build GeoJSON
        features = self._build_geojson_features(grid_lats, grid_lons, densities)

        return {
            "type": "FeatureCollection",
            "features": features,
            "metadata": {
                "incident_count": len(coordinates),
                "days": days,
                "incident_type": incident_type,
                "bounds": {
                    "min_lat": min_lat,
                    "max_lat": max_lat,
                    "min_lon": min_lon,
                    "max_lon": max_lon,
                },
                "max_density": float(np.max(densities)),
                "generated_at": datetime.utcnow().isoformat(),
                "grid_resolution": self.GRID_RESOLUTION,
            },
        }

    def _compute_kde(
        self,
        lats: np.ndarray,
        lons: np.ndarray,
        min_lat: float,
        max_lat: float,
        min_lon: float,
        max_lon: float,
    ) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
        """Compute Gaussian KDE on incident coordinates."""
        # Normalize coordinates for KDE
        stack = np.vstack([lats, lons])
        kde = gaussian_kde(stack, bw_method="scott")

        # Create evaluation grid
        grid_lat = np.linspace(min_lat, max_lat, self.GRID_RESOLUTION)
        grid_lon = np.linspace(min_lon, max_lon, self.GRID_RESOLUTION)
        grid_lat_mesh, grid_lon_mesh = np.meshgrid(grid_lat, grid_lon)

        # Evaluate KDE on grid
        positions = np.vstack([
            grid_lat_mesh.ravel(),
            grid_lon_mesh.ravel(),
        ])
        densities = kde(positions).reshape(self.GRID_RESOLUTION, self.GRID_RESOLUTION)

        # Normalize to [0, 1]
        max_density = densities.max()
        if max_density > 0:
            densities = densities / max_density

        return grid_lat_mesh, grid_lon_mesh, densities

    def _build_geojson_features(
        self,
        grid_lats: np.ndarray,
        grid_lons: np.ndarray,
        densities: np.ndarray,
    ) -> list[dict[str, Any]]:
        """Convert density grid to GeoJSON point features."""
        features = []
        threshold = 0.05  # Only include points above 5% of max density

        for i in range(self.GRID_RESOLUTION):
            for j in range(self.GRID_RESOLUTION):
                density = float(densities[j, i])
                if density < threshold:
                    continue

                lat = float(grid_lats[j, i])
                lon = float(grid_lons[j, i])

                features.append({
                    "type": "Feature",
                    "geometry": {
                        "type": "Point",
                        "coordinates": [lon, lat],
                    },
                    "properties": {
                        "density": round(density, 4),
                        "intensity": self._density_to_intensity(density),
                        "risk_level": self._density_to_risk(density),
                    },
                })

        return features

    def _density_to_intensity(self, density: float) -> float:
        """Map normalized density to heatmap intensity [0, 1]."""
        # Use sigmoid-like scaling for better visual contrast
        return float(1 / (1 + np.exp(-10 * (density - 0.5))))

    def _density_to_risk(self, density: float) -> str:
        if density < 0.25:
            return "LOW"
        elif density < 0.50:
            return "MEDIUM"
        elif density < 0.75:
            return "HIGH"
        else:
            return "CRITICAL"

    def _empty_heatmap_response(
        self, bounds: tuple, days: int
    ) -> dict[str, Any]:
        return {
            "type": "FeatureCollection",
            "features": [],
            "metadata": {
                "incident_count": 0,
                "days": days,
                "message": "Insufficient data for heatmap generation",
                "generated_at": datetime.utcnow().isoformat(),
            },
        }

    async def _fetch_incident_coordinates(
        self,
        days: int,
        incident_type: str | None,
        bounds: tuple[float, float, float, float],
    ) -> list[dict[str, float]]:
        """Fetch incident lat/lon coordinates from MongoDB."""
        min_lat, max_lat, min_lon, max_lon = bounds
        since = datetime.utcnow() - timedelta(days=days)

        query: dict[str, Any] = {
            "created_at": {"$gte": since},
            "location": {
                "$geoWithin": {
                    "$box": [
                        [min_lon, min_lat],
                        [max_lon, max_lat],
                    ]
                }
            },
        }

        if incident_type:
            query["incident_type"] = incident_type

        cursor = self._db[self.COLLECTION_NAME].find(
            query,
            {"location.coordinates": 1, "_id": 0},
        ).limit(10000)

        coordinates = []
        async for doc in cursor:
            try:
                coords = doc["location"]["coordinates"]  # [lon, lat]
                coordinates.append({"lat": coords[1], "lon": coords[0]})
            except (KeyError, IndexError):
                continue

        return coordinates

    async def get_point_density(self, lat: float, lon: float) -> float:
        """
        Get the crime density at a specific point.
        Used for route safety scoring.
        """
        cache_key = f"point_density:{lat:.4f}:{lon:.4f}"
        cached = await self._redis.get(cache_key)
        if cached:
            return float(cached)

        # Count incidents within 500m radius in last 30 days
        since = datetime.utcnow() - timedelta(days=30)

        try:
            count = await self._db[self.COLLECTION_NAME].count_documents({
                "created_at": {"$gte": since},
                "location": {
                    "$nearSphere": {
                        "$geometry": {"type": "Point", "coordinates": [lon, lat]},
                        "$maxDistance": 500,  # 500 meters
                    }
                },
            })

            # Normalize: 10+ incidents = max density 1.0
            density = min(count / 10.0, 1.0)
            await self._redis.setex(cache_key, 3600, str(density))
            return density

        except Exception as exc:
            logger.warning(f"Could not fetch density for ({lat}, {lon}): {exc}")
            return 0.0

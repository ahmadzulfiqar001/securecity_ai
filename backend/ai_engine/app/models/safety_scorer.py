"""
SecureCity AI — SafetyScorer
Multi-factor weighted safety score computation (0-100).
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

import numpy as np
from loguru import logger


# ─────────────────────────────────────────────────────────────
# Factor weights (must sum to 1.0)
# ─────────────────────────────────────────────────────────────
FACTOR_WEIGHTS = {
    "crime_rate": 0.30,
    "incident_count": 0.25,
    "response_time": 0.15,
    "lighting_score": 0.10,
    "population_density": 0.10,
    "time_of_day": 0.10,
}

assert abs(sum(FACTOR_WEIGHTS.values()) - 1.0) < 1e-6, "Weights must sum to 1.0"


class SafetyScorer:
    """
    Multi-factor weighted safety score computation.

    Each factor is normalized to a [0, 1] sub-score, then combined
    with configurable weights into a final [0, 100] safety score.

    Higher score = safer area.
    """

    def __init__(self, weights: dict[str, float] | None = None) -> None:
        self._weights = weights or FACTOR_WEIGHTS
        self._computed_at: datetime | None = None

    def compute_score(
        self,
        zone_id: str,
        crime_rate: float,          # incidents per km² per day
        incident_count_24h: int,    # incidents in last 24h in zone
        avg_response_time_minutes: float,  # police/emergency response time
        lighting_score: float,      # 0-1 (sensor/infra data)
        population_density: float,  # persons per km²
        hour: int,                  # 0-23
    ) -> dict[str, Any]:
        """
        Compute a comprehensive safety score for a geographic zone.

        Returns:
            dict containing:
                - safety_score: float [0, 100]
                - safety_level: str (VERY_SAFE/SAFE/MODERATE/UNSAFE/DANGEROUS)
                - factor_scores: dict of individual factor scores
                - factor_weights: dict of weights used
                - recommendations: list of improvement suggestions
        """
        # ── Factor sub-scores (all normalized to [0, 1]) ────────

        # Crime rate: 0 = 0 incidents/km²/day (perfect), 10+ = 0 (terrible)
        crime_sub = max(0.0, 1.0 - min(crime_rate / 10.0, 1.0))

        # Incident count: 0 = perfect, 20+ = 0
        incident_sub = max(0.0, 1.0 - min(incident_count_24h / 20.0, 1.0))

        # Response time: ≤3 min = perfect (1.0), 30+ min = 0
        response_sub = max(0.0, 1.0 - min((avg_response_time_minutes - 3.0) / 27.0, 1.0))
        response_sub = max(0.0, response_sub)

        # Lighting: already 0-1 (1 = fully lit)
        lighting_sub = max(0.0, min(lighting_score, 1.0))

        # Population density: moderate density (~2000/km²) is safest
        # Very low (isolated) or very high (crowd pressure) reduce score
        density_normalized = population_density / 10000.0
        population_sub = float(np.exp(-0.5 * ((density_normalized - 0.2) / 0.15) ** 2))

        # Time of day: daytime is safer
        time_sub = self._compute_time_of_day_score(hour)

        # ── Weighted combination ────────────────────────────────
        sub_scores = {
            "crime_rate": crime_sub,
            "incident_count": incident_sub,
            "response_time": response_sub,
            "lighting_score": lighting_sub,
            "population_density": population_sub,
            "time_of_day": time_sub,
        }

        raw_score = sum(
            sub_scores[factor] * weight
            for factor, weight in self._weights.items()
        )

        # Scale to 0-100 and round
        safety_score = round(raw_score * 100, 1)

        # Safety level
        safety_level = self._get_safety_level(safety_score)

        # Recommendations
        recommendations = self._generate_recommendations(sub_scores, safety_score)

        self._computed_at = datetime.utcnow()

        return {
            "zone_id": zone_id,
            "safety_score": safety_score,
            "safety_level": safety_level,
            "factor_scores": {k: round(v * 100, 1) for k, v in sub_scores.items()},
            "factor_weights": self._weights,
            "recommendations": recommendations,
            "computed_at": self._computed_at.isoformat(),
        }

    def _compute_time_of_day_score(self, hour: int) -> float:
        """Compute time-of-day safety sub-score using a sinusoidal model."""
        # Peak safety at noon (hour=12), minimum at 2am (hour=2)
        # Score = 0.5 + 0.5 * cos(pi * (hour - 12) / 12) ... shifted so min ~2am
        angle = np.pi * (hour - 14) / 12
        raw = 0.5 + 0.4 * np.cos(angle)
        return float(np.clip(raw, 0.0, 1.0))

    def _get_safety_level(self, score: float) -> str:
        if score >= 80:
            return "VERY_SAFE"
        elif score >= 60:
            return "SAFE"
        elif score >= 40:
            return "MODERATE"
        elif score >= 20:
            return "UNSAFE"
        else:
            return "DANGEROUS"

    def _generate_recommendations(
        self, sub_scores: dict[str, float], total_score: float
    ) -> list[str]:
        """Generate human-readable recommendations based on weak factors."""
        recommendations = []

        if sub_scores["crime_rate"] < 0.4:
            recommendations.append("High crime rate in area — exercise caution and stay on main streets.")
        if sub_scores["incident_count"] < 0.4:
            recommendations.append("Multiple incidents reported recently — consider alternate route.")
        if sub_scores["response_time"] < 0.5:
            recommendations.append("Emergency response times are elevated — pre-call 911 if concerned.")
        if sub_scores["lighting_score"] < 0.4:
            recommendations.append("Poor street lighting — use well-lit paths or travel with companions.")
        if sub_scores["time_of_day"] < 0.4:
            recommendations.append("Nighttime travel increases risk — consider delaying trip until morning.")
        if total_score < 30:
            recommendations.append("⚠️ This area is currently HIGH RISK — strongly consider alternatives.")

        if not recommendations:
            recommendations.append("Area appears safe. Stay aware of your surroundings.")

        return recommendations

    async def score_route(
        self,
        route_coordinates: list[list[float]],
        hour: int,
        heatmap_service: Any,
    ) -> dict[str, Any]:
        """
        Score the safety of a route by sampling points along the path.

        Args:
            route_coordinates: list of [lon, lat] pairs
            hour: time of travel (0-23)
            heatmap_service: HeatmapService instance for density lookup

        Returns:
            dict with overall_score, segment_scores, danger_zones, safe_alternatives
        """
        if not route_coordinates:
            raise ValueError("Route coordinates cannot be empty")

        # Sample up to 20 points evenly along route
        n_samples = min(20, len(route_coordinates))
        step = max(1, len(route_coordinates) // n_samples)
        sampled = route_coordinates[::step]

        segment_scores = []
        danger_zones = []

        for i, coord in enumerate(sampled):
            lon, lat = coord[0], coord[1]
            # Simple lookup — in production, query actual zone data
            density = await heatmap_service.get_point_density(lat=lat, lon=lon)
            crime_rate = density * 5.0  # Scale density to crime rate estimate
            incident_count = int(density * 10)

            seg_result = self.compute_score(
                zone_id=f"route_seg_{i}",
                crime_rate=crime_rate,
                incident_count_24h=incident_count,
                avg_response_time_minutes=8.0,
                lighting_score=0.7 if (6 <= hour <= 20) else 0.3,
                population_density=2000.0,
                hour=hour,
            )

            segment_scores.append({
                "segment": i,
                "lat": lat,
                "lon": lon,
                "safety_score": seg_result["safety_score"],
                "safety_level": seg_result["safety_level"],
            })

            if seg_result["safety_score"] < 40:
                danger_zones.append({"lat": lat, "lon": lon, "score": seg_result["safety_score"]})

        # Overall route score = weighted average (ends matter more)
        scores = [s["safety_score"] for s in segment_scores]
        weights = np.linspace(0.5, 1.0, len(scores))
        weights /= weights.sum()
        overall_score = float(np.average(scores, weights=weights))

        return {
            "overall_score": round(overall_score, 1),
            "overall_level": self._get_safety_level(overall_score),
            "segment_count": len(segment_scores),
            "segment_scores": segment_scores,
            "danger_zones": danger_zones,
            "has_danger_zones": len(danger_zones) > 0,
            "recommendation": (
                "Route passes through high-risk zones. Consider alternative paths."
                if danger_zones else "Route appears safe."
            ),
        }

    def get_status(self) -> dict[str, Any]:
        return {
            "model_type": "WeightedMultiFactorScorer",
            "weights": self._weights,
            "last_computed": self._computed_at.isoformat() if self._computed_at else None,
            "version": "1.0.0",
        }

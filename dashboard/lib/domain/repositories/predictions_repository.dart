import '../../core/errors/result.dart';
import '../entities/heatmap_entity.dart';
import '../entities/safety_score_entity.dart';

/// Calls `ai_engine`'s prediction endpoints — the dashboard's second
/// Python-microservice client after cv_engine (see CvRepository).
abstract class PredictionsRepository {
  Future<Result<HeatmapEntity>> getCrimeHeatmap({
    int days = 30,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  });

  /// Only [zoneId] carries real signal from the caller — the remaining
  /// factors (crime rate, incident count, lighting, etc.) use ai_engine's
  /// documented defaults since the dashboard has no live per-point sensor
  /// data for an arbitrary tapped map location.
  Future<Result<SafetyScoreEntity>> getSafetyScore({required String zoneId, int? hour});
}

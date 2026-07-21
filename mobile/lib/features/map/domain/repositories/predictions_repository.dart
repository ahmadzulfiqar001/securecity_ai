import '../../../../core/errors/failures.dart';
import '../entities/heatmap_entity.dart';
import '../entities/route_safety_entity.dart';

/// Calls the `ai_engine` microservice's prediction endpoints — the first
/// real feature usage of `apiClientProvider` (core/network/api_client.dart),
/// which was built but previously unused by any repository.
abstract class PredictionsRepository {
  Future<Result<HeatmapEntity>> getCrimeHeatmap({
    int days = 30,
    String? incidentType,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  });

  /// [coordinates] is a list of `[lon, lat]` pairs — at minimum a
  /// [start, destination] pair for a straight-line route (this app has no
  /// turn-by-turn Directions API integration).
  Future<Result<RouteSafetyEntity>> scoreRoute({
    required List<List<double>> coordinates,
    int? hour,
  });
}

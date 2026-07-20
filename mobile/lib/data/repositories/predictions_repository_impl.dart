import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/heatmap_entity.dart';
import '../../domain/entities/route_safety_entity.dart';
import '../../domain/repositories/predictions_repository.dart';

class PredictionsRepositoryImpl implements PredictionsRepository {
  final ApiClient _apiClient;

  PredictionsRepositoryImpl(this._apiClient);

  @override
  Future<Result<HeatmapEntity>> getCrimeHeatmap({
    int days = 30,
    String? incidentType,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        '/predict/heatmap',
        queryParameters: {
          'days': days,
          if (incidentType != null) 'incident_type': incidentType,
          if (minLat != null) 'min_lat': minLat,
          if (maxLat != null) 'max_lat': maxLat,
          if (minLon != null) 'min_lon': minLon,
          if (maxLon != null) 'max_lon': maxLon,
        },
      );
      return Success(HeatmapEntity.fromJson(data));
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<RouteSafetyEntity>> scoreRoute({
    required List<List<double>> coordinates,
    int? hour,
  }) async {
    try {
      final data = await _apiClient.post<Map<String, dynamic>>(
        '/predict/route-safety',
        data: {
          'coordinates': coordinates,
          if (hour != null) 'hour': hour,
        },
      );
      return Success(RouteSafetyEntity.fromJson(data));
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }
}

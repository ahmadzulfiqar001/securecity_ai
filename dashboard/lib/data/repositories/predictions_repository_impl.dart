import 'package:dio/dio.dart';

import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/heatmap_entity.dart';
import '../../domain/entities/safety_score_entity.dart';
import '../../domain/repositories/predictions_repository.dart';

class PredictionsRepositoryImpl implements PredictionsRepository {
  final Dio _dio;

  PredictionsRepositoryImpl(this._dio);

  @override
  Future<Result<HeatmapEntity>> getCrimeHeatmap({
    int days = 30,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/predict/heatmap',
        queryParameters: {
          'days': days,
          if (minLat != null) 'min_lat': minLat,
          if (maxLat != null) 'max_lat': maxLat,
          if (minLon != null) 'min_lon': minLon,
          if (maxLon != null) 'max_lon': maxLon,
        },
      );
      return Success(HeatmapEntity.fromJson(response.data ?? {}));
    } on DioException catch (e) {
      return Error(describeDioError(e, serviceName: 'AI Engine'));
    } catch (e) {
      return Error('Failed to load crime heatmap: $e');
    }
  }

  @override
  Future<Result<SafetyScoreEntity>> getSafetyScore({required String zoneId, int? hour}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/predict/safety-score',
        data: {
          'zone_id': zoneId,
          if (hour != null) 'hour': hour,
        },
      );
      return Success(SafetyScoreEntity.fromJson(response.data ?? {}));
    } on DioException catch (e) {
      return Error(describeDioError(e, serviceName: 'AI Engine'));
    } catch (e) {
      return Error('Failed to load safety score: $e');
    }
  }
}

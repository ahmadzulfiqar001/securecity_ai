import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/camera_stream_entity.dart';
import '../../domain/entities/detection_event_entity.dart';
import '../../domain/repositories/cv_repository.dart';

class CvRepositoryImpl implements CvRepository {
  final Dio _dio;

  CvRepositoryImpl(this._dio);

  @override
  Future<Result<List<CameraStreamEntity>>> listStreams() async {
    try {
      final response = await _dio.get<List<dynamic>>('/streams/');
      final streams = (response.data ?? [])
          .map((e) => CameraStreamEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(streams);
    } on DioException catch (e) {
      return Error(describeDioError(e, serviceName: 'Computer Vision service'));
    } catch (e) {
      return Error('Failed to load camera streams: $e');
    }
  }

  @override
  Future<Result<List<DetectionEventEntity>>> recentDetections({String? cameraId, int limit = 50}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/detections/',
        queryParameters: {
          if (cameraId != null) 'camera_id': cameraId,
          'limit': limit,
        },
      );
      final events = (response.data ?? [])
          .map((e) => DetectionEventEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(events);
    } on DioException catch (e) {
      return Error(describeDioError(e, serviceName: 'Computer Vision service'));
    } catch (e) {
      return Error('Failed to load recent detections: $e');
    }
  }

  @override
  Stream<DetectionEventEntity> watchCameraEvents(String cameraId) {
    final uri = Uri.parse('${AppConstants.cvEngineWsBaseUrl}/ws/stream/$cameraId');
    final channel = WebSocketChannel.connect(uri);

    final controller = StreamController<DetectionEventEntity>();
    channel.stream.listen(
      (raw) {
        if (raw is! String) return;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        if (decoded['type'] != 'detections') return;
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data == null) return;
        controller.add(DetectionEventEntity.fromJson(data));
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () => channel.sink.close();

    return controller.stream;
  }
}

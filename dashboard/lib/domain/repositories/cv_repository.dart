import '../../core/errors/result.dart';
import '../entities/camera_stream_entity.dart';
import '../entities/detection_event_entity.dart';

abstract class CvRepository {
  Future<Result<List<CameraStreamEntity>>> listStreams();

  Future<Result<List<DetectionEventEntity>>> recentDetections({String? cameraId, int limit = 50});

  /// Live detection events for a single camera, over cv_engine's
  /// `/ws/stream/{camera_id}` WebSocket.
  Stream<DetectionEventEntity> watchCameraEvents(String cameraId);
}

/// A registered camera stream, as reported by cv_engine's GET /streams/.
class CameraStreamEntity {
  final String streamId;
  final String cameraId;
  final String rtspUrl;
  final String status; // 'running' | 'stopped'
  final double fps;
  final DateTime startedAt;

  CameraStreamEntity({
    required this.streamId,
    required this.cameraId,
    required this.rtspUrl,
    required this.status,
    required this.fps,
    required this.startedAt,
  });

  factory CameraStreamEntity.fromJson(Map<String, dynamic> json) {
    return CameraStreamEntity(
      streamId: json['stream_id'] as String? ?? '',
      cameraId: json['camera_id'] as String? ?? '',
      rtspUrl: json['rtsp_url'] as String? ?? '',
      status: json['status'] as String? ?? 'stopped',
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

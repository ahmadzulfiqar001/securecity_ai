/// A single frame's analysis result from cv_engine — shaped after its
/// AnalysisResult schema (app/schemas.py) and the live event payload
/// StreamProcessor broadcasts over WebSocket (app/streams/stream_manager.py).
class DetectionEventEntity {
  final String cameraId;
  final DateTime timestamp;
  final double fps;
  final List<Map<String, dynamic>> detections;
  final Map<String, dynamic>? crowdAnalysis;
  final Map<String, dynamic>? fireSmokeAnalysis;
  final Map<String, dynamic>? weaponAnalysis;
  final Map<String, dynamic>? behaviorAnalysis;
  final Map<String, dynamic>? accidentAnalysis;

  DetectionEventEntity({
    required this.cameraId,
    required this.timestamp,
    required this.fps,
    required this.detections,
    this.crowdAnalysis,
    this.fireSmokeAnalysis,
    this.weaponAnalysis,
    this.behaviorAnalysis,
    this.accidentAnalysis,
  });

  factory DetectionEventEntity.fromJson(Map<String, dynamic> json) {
    return DetectionEventEntity(
      cameraId: json['camera_id'] as String? ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      detections: (json['detections'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      crowdAnalysis: (json['crowd_analysis'] as Map?)?.cast<String, dynamic>(),
      fireSmokeAnalysis: (json['fire_smoke_analysis'] as Map?)?.cast<String, dynamic>(),
      weaponAnalysis: (json['weapon_analysis'] as Map?)?.cast<String, dynamic>(),
      behaviorAnalysis: (json['behavior_analysis'] as Map?)?.cast<String, dynamic>(),
      accidentAnalysis: (json['accident_analysis'] as Map?)?.cast<String, dynamic>(),
    );
  }

  bool get hasAlert =>
      (weaponAnalysis?['weapon_detected'] == true) ||
      (accidentAnalysis?['accident_suspected'] == true) ||
      (fireSmokeAnalysis?['detected'] == true) ||
      (behaviorAnalysis?['alert_triggered'] == true) ||
      (crowdAnalysis?['is_alert'] == true);

  /// Highest-priority label to show as a chip, or null if nothing notable.
  String? get primarySeverityLabel {
    if (weaponAnalysis?['weapon_detected'] == true) return 'WEAPON';
    if (accidentAnalysis?['accident_suspected'] == true) return 'ACCIDENT';
    if (fireSmokeAnalysis?['detected'] == true) return 'FIRE/SMOKE';
    if (behaviorAnalysis?['alert_triggered'] == true) return 'SUSPICIOUS';
    if (crowdAnalysis?['is_alert'] == true) return 'CROWD';
    return null;
  }
}

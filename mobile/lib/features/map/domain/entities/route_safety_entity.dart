/// Result of scoring a route's safety (`POST /predict/route-safety` on
/// `ai_engine` - see `SafetyScorer.score_route()`). Segment/danger-zone
/// entries are kept as loose maps (`segment`/`lat`/`lon`/`safety_score`/
/// `safety_level` and `lat`/`lon`/`score` respectively) matching the
/// backend's exact response shape, rather than duplicating typed classes
/// for a shape only ever read for map rendering.
class RouteSafetyEntity {
  final double overallScore;
  final String overallLevel;
  final List<Map<String, dynamic>> segmentScores;
  final List<Map<String, dynamic>> dangerZones;
  final bool hasDangerZones;
  final String recommendation;

  RouteSafetyEntity({
    required this.overallScore,
    required this.overallLevel,
    required this.segmentScores,
    required this.dangerZones,
    required this.hasDangerZones,
    required this.recommendation,
  });

  factory RouteSafetyEntity.fromJson(Map<String, dynamic> json) {
    return RouteSafetyEntity(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      overallLevel: json['overall_level'] as String? ?? 'MODERATE',
      segmentScores: (json['segment_scores'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      dangerZones: (json['danger_zones'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      hasDangerZones: json['has_danger_zones'] as bool? ?? false,
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}

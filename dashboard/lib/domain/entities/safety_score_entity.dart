/// Location Intelligence panel data (`POST /predict/safety-score` on
/// `ai_engine` — see `SafetyScorer.compute_score()`).
class SafetyScoreEntity {
  final String zoneId;
  final double safetyScore;
  final String safetyLevel;
  final Map<String, double> factorScores;
  final List<String> recommendations;

  SafetyScoreEntity({
    required this.zoneId,
    required this.safetyScore,
    required this.safetyLevel,
    required this.factorScores,
    required this.recommendations,
  });

  factory SafetyScoreEntity.fromJson(Map<String, dynamic> json) {
    return SafetyScoreEntity(
      zoneId: json['zone_id'] as String? ?? '',
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 0.0,
      safetyLevel: json['safety_level'] as String? ?? 'MODERATE',
      factorScores: (json['factor_scores'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      recommendations:
          (json['recommendations'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }
}

/// Summary of the user's current-zone safety score shown on Home's
/// dashboard card. Kept separate from the `area_safety` feature's own
/// entity — features stay independent, so Home owns its own (currently
/// local/static) read of "what to show right now" rather than importing
/// area_safety's repository.
class SafetyScoreEntity {
  final double score; // 0-100
  final String label;
  final String summary;

  SafetyScoreEntity({
    required this.score,
    required this.label,
    required this.summary,
  });
}

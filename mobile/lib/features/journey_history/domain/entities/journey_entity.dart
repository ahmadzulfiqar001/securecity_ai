/// A single recorded trip. Written by the future live Journey Tracking
/// feature (not part of this pass) - this entity/repository only reads
/// what's already in Firestore.
class JourneyEntity {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<double> startLocation; // [lng, lat]
  final List<double>? endLocation;
  final String status; // 'active' | 'completed' | 'cancelled'
  final double? distanceMeters;

  JourneyEntity({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.startLocation,
    this.endLocation,
    required this.status,
    this.distanceMeters,
  });
}

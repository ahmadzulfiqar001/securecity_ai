/// A citizen-triggered SOS alert. Nothing writes this collection yet (the
/// mobile app's SOS screen is UI-only pending backend wiring) — this
/// entity/repository defines the schema the Emergency Queue is built
/// against so it's ready the moment mobile SOS lands.
class SosEventEntity {
  final String id;
  final String userId;
  final String status; // 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED' | 'CANCELLED'
  final List<double> location; // [lng, lat]
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? acknowledgedBy;
  final String? message;

  SosEventEntity({
    required this.id,
    required this.userId,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.acknowledgedBy,
    this.message,
  });
}

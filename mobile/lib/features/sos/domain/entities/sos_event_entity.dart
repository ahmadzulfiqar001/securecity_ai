/// An active or resolved SOS alert, written to `AppConstants.colSosEvents`
/// when a citizen triggers the emergency flow. Authorities/dashboard
/// consume this collection to dispatch responders.
class SosEventEntity {
  final String userId;
  final double latitude;
  final double longitude;
  final String message;
  final String status; // 'active' | 'resolved'
  final String createdAt;
  final String? audioUrl;

  SosEventEntity({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.message,
    required this.status,
    required this.createdAt,
    this.audioUrl,
  });
}

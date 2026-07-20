/// An authority-drawn map zone (emergency / flood-risk / traffic),
/// managed here in Zone Manager and consumed by mobile for both map
/// display and client-side geofencing.
class MapZoneEntity {
  final String id;
  final String name;
  final String type; // see MapZoneType
  final List<List<double>> polygon; // [[lng, lat], ...]
  final String severity; // 'low' | 'medium' | 'high' | 'critical'
  final String? description;
  final String? trafficZoneId; // only meaningful for type == MapZoneType.traffic
  final bool active;
  final String createdBy;
  final DateTime updatedAt;

  MapZoneEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.polygon,
    required this.severity,
    this.description,
    this.trafficZoneId,
    required this.active,
    required this.createdBy,
    required this.updatedAt,
  });

  List<(double lat, double lng)> get latLngPoints => polygon.map((p) => (p[1], p[0])).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        // Stored as an array of {lng, lat} maps, not an array of arrays —
        // Firestore doesn't support nested arrays as a document field.
        'polygon': polygon.map((p) => {'lng': p[0], 'lat': p[1]}).toList(),
        'severity': severity,
        'description': description,
        'trafficZoneId': trafficZoneId,
        'active': active,
        'createdBy': createdBy,
      };
}

abstract final class MapZoneType {
  static const String emergency = 'emergency';
  static const String floodRisk = 'flood_risk';
  static const String traffic = 'traffic';

  static const List<String> all = [emergency, floodRisk, traffic];

  static String label(String type) => switch (type) {
        emergency => 'Emergency Zone',
        floodRisk => 'Flood Risk',
        traffic => 'Traffic Zone',
        _ => 'Zone',
      };
}

abstract final class MapZoneSeverity {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> all = [low, medium, high, critical];
}

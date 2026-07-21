/// An authority-drawn map zone (emergency / flood-risk / traffic),
/// managed from the dashboard's Zone Manager and consumed here for both
/// map display and client-side geofencing (see core/services/geofence_service.dart).
class MapZoneEntity {
  final String id;
  final String name;
  final String type; // see MapZoneType
  final List<List<double>> polygon; // [[lng, lat], ...], closed ring
  final String severity; // 'low' | 'medium' | 'high' | 'critical'
  final String? description;
  final String? trafficZoneId; // only set for type == MapZoneType.traffic
  final bool active;
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
    required this.updatedAt,
  });

  /// Points as (lat, lng) pairs, the order most map widgets expect.
  List<(double lat, double lng)> get latLngPoints =>
      polygon.map((p) => (p[1], p[0])).toList();
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

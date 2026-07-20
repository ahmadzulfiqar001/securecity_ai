import '../../domain/entities/map_zone_entity.dart';

/// Pure geofencing logic: point-in-polygon (ray casting) against a set of
/// active zones, with enter/exit tracking across successive location
/// updates. No Firestore/Geolocator dependency here — see
/// core/providers/geofence_provider.dart for the stream wiring, and
/// core/services/notification_service.dart for the alert delivery.
class GeofenceService {
  final Set<String> _insideZoneIds = {};

  /// Zone IDs the last [update] call found the position inside.
  Set<String> get insideZoneIds => Set.unmodifiable(_insideZoneIds);

  /// Feed the latest position + active zones; returns zones newly entered
  /// and newly exited since the previous call.
  ({List<MapZoneEntity> entered, List<MapZoneEntity> exited}) update(
    (double lat, double lng) position,
    List<MapZoneEntity> activeZones,
  ) {
    final zonesById = {for (final zone in activeZones) zone.id: zone};
    final currentlyInsideIds = <String>{
      for (final zone in activeZones)
        if (containsPoint(zone.latLngPoints, position)) zone.id,
    };

    final enteredIds = currentlyInsideIds.difference(_insideZoneIds);
    final exitedIds = _insideZoneIds.difference(currentlyInsideIds);

    _insideZoneIds
      ..clear()
      ..addAll(currentlyInsideIds);

    return (
      entered: [for (final id in enteredIds) if (zonesById[id] != null) zonesById[id]!],
      exited: [for (final id in exitedIds) if (zonesById[id] != null) zonesById[id]!],
    );
  }

  /// Ray-casting point-in-polygon test. `polygon` is a ring of (lat, lng)
  /// points (closed or open — the ring is implicitly closed); `point` is
  /// (lat, lng). Returns false for degenerate polygons (< 3 points).
  bool containsPoint(List<(double lat, double lng)> polygon, (double lat, double lng) point) {
    if (polygon.length < 3) return false;

    bool inside = false;
    final (px, py) = point;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final (xi, yi) = polygon[i];
      final (xj, yj) = polygon[j];

      final intersects = ((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
    }

    return inside;
  }
}

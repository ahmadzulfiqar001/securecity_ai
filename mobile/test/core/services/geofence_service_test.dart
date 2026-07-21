import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_ai/core/services/geofence_service.dart';
import 'package:securecity_ai/features/map/domain/entities/map_zone_entity.dart';

MapZoneEntity _squareZone(String id, {double minLat = 0, double maxLat = 1, double minLng = 0, double maxLng = 1}) {
  return MapZoneEntity(
    id: id,
    name: 'Zone $id',
    type: MapZoneType.emergency,
    polygon: [
      [minLng, minLat],
      [maxLng, minLat],
      [maxLng, maxLat],
      [minLng, maxLat],
      [minLng, minLat],
    ],
    severity: 'high',
    active: true,
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('containsPoint', () {
    final service = GeofenceService();
    final square = [(0.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 0.0)];

    test('returns true for a point inside the polygon', () {
      expect(service.containsPoint(square, (0.5, 0.5)), isTrue);
    });

    test('returns false for a point outside the polygon', () {
      expect(service.containsPoint(square, (2.0, 2.0)), isFalse);
    });

    test('returns false for a degenerate polygon (< 3 points)', () {
      expect(service.containsPoint([(0.0, 0.0), (1.0, 1.0)], (0.5, 0.5)), isFalse);
    });
  });

  group('update', () {
    test('reports a zone as entered the first time a point falls inside it', () {
      final service = GeofenceService();
      final zone = _squareZone('z1');

      final result = service.update((0.5, 0.5), [zone]);

      expect(result.entered.map((z) => z.id), ['z1']);
      expect(result.exited, isEmpty);
      expect(service.insideZoneIds, {'z1'});
    });

    test('does not re-report a zone already entered on a subsequent call', () {
      final service = GeofenceService();
      final zone = _squareZone('z1');

      service.update((0.5, 0.5), [zone]);
      final second = service.update((0.6, 0.6), [zone]);

      expect(second.entered, isEmpty);
      expect(second.exited, isEmpty);
    });

    test('reports a zone as exited once the point leaves it', () {
      final service = GeofenceService();
      final zone = _squareZone('z1');

      service.update((0.5, 0.5), [zone]);
      final result = service.update((5.0, 5.0), [zone]);

      expect(result.exited.map((z) => z.id), ['z1']);
      expect(result.entered, isEmpty);
      expect(service.insideZoneIds, isEmpty);
    });

    test('tracks multiple overlapping zones independently', () {
      final service = GeofenceService();
      final small = _squareZone('small', minLat: 0, maxLat: 1, minLng: 0, maxLng: 1);
      final big = _squareZone('big', minLat: -5, maxLat: 5, minLng: -5, maxLng: 5);

      final result = service.update((0.5, 0.5), [small, big]);

      expect(result.entered.map((z) => z.id).toSet(), {'small', 'big'});

      final exitSmallOnly = service.update((3.0, 3.0), [small, big]);
      expect(exitSmallOnly.exited.map((z) => z.id), ['small']);
      expect(exitSmallOnly.entered, isEmpty);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_ai/data/repositories/map_zone_repository_impl.dart';
import 'package:securecity_ai/domain/entities/map_zone_entity.dart';

void main() {
  test('watchActive streams only zones with active == true', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('map_zones').add({
      'name': 'Downtown Flood Risk',
      'type': MapZoneType.floodRisk,
      'polygon': [
        {'lng': 67.00, 'lat': 24.85},
        {'lng': 67.01, 'lat': 24.85},
        {'lng': 67.01, 'lat': 24.86},
        {'lng': 67.00, 'lat': 24.86},
      ],
      'severity': 'high',
      'active': true,
      'updatedAt': Timestamp.now(),
    });
    await firestore.collection('map_zones').add({
      'name': 'Old Emergency Zone',
      'type': MapZoneType.emergency,
      'polygon': [
        {'lng': 67.00, 'lat': 24.85},
        {'lng': 67.01, 'lat': 24.85},
        {'lng': 67.01, 'lat': 24.86},
      ],
      'severity': 'medium',
      'active': false,
      'updatedAt': Timestamp.now(),
    });

    final repository = MapZoneRepositoryImpl(firestore);
    final zones = await repository.watchActive().first;

    expect(zones, hasLength(1));
    expect(zones.first.name, 'Downtown Flood Risk');
    expect(zones.first.type, MapZoneType.floodRisk);
    expect(zones.first.polygon, hasLength(4));
    expect(zones.first.latLngPoints.first, (24.85, 67.00));
  });

  test('defaults missing fields sensibly', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('map_zones').add({
      'active': true,
      'polygon': <Map<String, double>>[],
    });

    final repository = MapZoneRepositoryImpl(firestore);
    final zones = await repository.watchActive().first;

    expect(zones, hasLength(1));
    expect(zones.first.name, 'Unnamed Zone');
    expect(zones.first.type, MapZoneType.emergency);
    expect(zones.first.severity, 'medium');
    expect(zones.first.polygon, isEmpty);
  });
}

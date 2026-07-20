import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_dashboard/core/errors/result.dart';
import 'package:securecity_dashboard/data/repositories/map_zone_repository_impl.dart';
import 'package:securecity_dashboard/domain/entities/map_zone_entity.dart';

MapZoneEntity _zone({String id = '', String type = MapZoneType.emergency}) {
  return MapZoneEntity(
    id: id,
    name: 'Test Zone',
    type: type,
    polygon: [
      [67.00, 24.85],
      [67.01, 24.85],
      [67.01, 24.86],
      [67.00, 24.86],
    ],
    severity: MapZoneSeverity.high,
    active: true,
    createdBy: 'officer-1',
    updatedAt: DateTime(2026),
  );
}

void main() {
  test('createZone then watchAll reflects the new zone', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = MapZoneRepositoryImpl(firestore);

    final result = await repository.createZone(_zone());
    expect(result, isA<Success<void>>());

    final zones = await repository.watchAll().first;
    expect(zones, hasLength(1));
    expect(zones.first.name, 'Test Zone');
    expect(zones.first.type, MapZoneType.emergency);
  });

  test('updateZone changes the stored fields', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = MapZoneRepositoryImpl(firestore);
    await repository.createZone(_zone());

    final created = (await repository.watchAll().first).first;
    final updateResult = await repository.updateZone(
      MapZoneEntity(
        id: created.id,
        name: 'Renamed Zone',
        type: MapZoneType.floodRisk,
        polygon: created.polygon,
        severity: MapZoneSeverity.critical,
        active: true,
        createdBy: created.createdBy,
        updatedAt: DateTime.now(),
      ),
    );

    expect(updateResult, isA<Success<void>>());
    final zones = await repository.watchAll().first;
    expect(zones.first.name, 'Renamed Zone');
    expect(zones.first.type, MapZoneType.floodRisk);
    expect(zones.first.severity, MapZoneSeverity.critical);
  });

  test('deleteZone removes it from watchAll', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = MapZoneRepositoryImpl(firestore);
    await repository.createZone(_zone());
    final created = (await repository.watchAll().first).first;

    final deleteResult = await repository.deleteZone(created.id);

    expect(deleteResult, isA<Success<void>>());
    final zones = await repository.watchAll().first;
    expect(zones, isEmpty);
  });
}

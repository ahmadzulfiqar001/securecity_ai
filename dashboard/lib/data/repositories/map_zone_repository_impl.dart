import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../domain/entities/map_zone_entity.dart';
import '../../domain/repositories/map_zone_repository.dart';

class MapZoneRepositoryImpl implements MapZoneRepository {
  final FirebaseFirestore _firestore;

  MapZoneRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.colMapZones);

  @override
  Stream<List<MapZoneEntity>> watchAll() {
    return _collection.snapshots().map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<Result<void>> createZone(MapZoneEntity zone) async {
    try {
      await _collection.add({
        ...zone.toJson(),
        'updatedAt': Timestamp.now(),
      });
      return const Success(null);
    } catch (e) {
      return Error('Failed to create zone: $e');
    }
  }

  @override
  Future<Result<void>> updateZone(MapZoneEntity zone) async {
    try {
      await _collection.doc(zone.id).update({
        ...zone.toJson(),
        'updatedAt': Timestamp.now(),
      });
      return const Success(null);
    } catch (e) {
      return Error('Failed to update zone: $e');
    }
  }

  @override
  Future<Result<void>> deleteZone(String zoneId) async {
    try {
      await _collection.doc(zoneId).delete();
      return const Success(null);
    } catch (e) {
      return Error('Failed to delete zone: $e');
    }
  }

  MapZoneEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MapZoneEntity(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Zone',
      type: data['type'] as String? ?? MapZoneType.emergency,
      polygon: (data['polygon'] as List<dynamic>? ?? [])
          .map((point) => point as Map<String, dynamic>)
          .map((point) => [(point['lng'] as num).toDouble(), (point['lat'] as num).toDouble()])
          .toList(),
      severity: data['severity'] as String? ?? MapZoneSeverity.medium,
      description: data['description'] as String?,
      trafficZoneId: data['trafficZoneId'] as String?,
      active: data['active'] as bool? ?? true,
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

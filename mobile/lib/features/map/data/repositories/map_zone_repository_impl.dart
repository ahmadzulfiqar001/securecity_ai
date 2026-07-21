import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/map_zone_entity.dart';
import '../../domain/repositories/map_zone_repository.dart';

class MapZoneRepositoryImpl implements MapZoneRepository {
  final FirebaseFirestore _firestore;

  MapZoneRepositoryImpl(this._firestore);

  @override
  Stream<List<MapZoneEntity>> watchActive() {
    return _firestore
        .collection(AppConstants.colMapZones)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  MapZoneEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MapZoneEntity(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Zone',
      type: data['type'] as String? ?? MapZoneType.emergency,
      // Stored as an array of {lng, lat} maps, not an array of arrays —
      // Firestore doesn't support nested arrays as a document field.
      polygon: (data['polygon'] as List<dynamic>? ?? [])
          .map((point) => point as Map<String, dynamic>)
          .map((point) => [(point['lng'] as num).toDouble(), (point['lat'] as num).toDouble()])
          .toList(),
      severity: data['severity'] as String? ?? 'medium',
      description: data['description'] as String?,
      trafficZoneId: data['trafficZoneId'] as String?,
      active: data['active'] as bool? ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

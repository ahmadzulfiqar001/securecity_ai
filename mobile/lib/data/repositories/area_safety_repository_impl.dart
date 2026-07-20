import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/area_safety_entity.dart';
import '../../domain/repositories/area_safety_repository.dart';

class AreaSafetyRepositoryImpl implements AreaSafetyRepository {
  final FirebaseFirestore _firestore;

  AreaSafetyRepositoryImpl(this._firestore);

  @override
  Stream<List<AreaSafetyEntity>> watchAll() {
    return _firestore
        .collection(AppConstants.colAreaSafety)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  AreaSafetyEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AreaSafetyEntity(
      id: doc.id,
      zoneName: data['zoneName'] as String? ?? 'Unknown Zone',
      safetyScore: (data['safetyScore'] as num?)?.toDouble() ?? 0.0,
      summary: data['summary'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

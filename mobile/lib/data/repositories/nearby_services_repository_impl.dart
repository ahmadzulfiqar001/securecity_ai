import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/nearby_service_entity.dart';
import '../../domain/repositories/nearby_services_repository.dart';

class NearbyServicesRepositoryImpl implements NearbyServicesRepository {
  final FirebaseFirestore _firestore;

  NearbyServicesRepositoryImpl(this._firestore);

  @override
  Stream<List<NearbyServiceEntity>> watchAll() {
    return _firestore
        .collection(AppConstants.colNearbyServices)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  NearbyServiceEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return NearbyServiceEntity(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      type: data['type'] as String? ?? 'police',
      phone: data['phone'] as String?,
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

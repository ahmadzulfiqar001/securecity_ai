import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../domain/entities/sos_event_entity.dart';
import '../../domain/repositories/emergency_queue_repository.dart';

class EmergencyQueueRepositoryImpl implements EmergencyQueueRepository {
  final FirebaseFirestore _firestore;

  EmergencyQueueRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.colSosEvents);

  @override
  Stream<List<SosEventEntity>> watchActive() {
    return _collection
        .where('status', isEqualTo: 'ACTIVE')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<Result<void>> acknowledge(String sosId, String authorityUid) async {
    try {
      await _collection.doc(sosId).update({
        'status': 'ACKNOWLEDGED',
        'acknowledgedBy': authorityUid,
        'updatedAt': Timestamp.now(),
      });
      return const Success(null);
    } catch (e) {
      return Error('Failed to acknowledge SOS alert: $e');
    }
  }

  SosEventEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SosEventEntity(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      status: data['status'] as String? ?? 'ACTIVE',
      location: (data['location'] as List<dynamic>? ?? [0.0, 0.0])
          .map((e) => (e as num).toDouble())
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acknowledgedBy: data['acknowledgedBy'] as String?,
      message: data['message'] as String?,
    );
  }
}

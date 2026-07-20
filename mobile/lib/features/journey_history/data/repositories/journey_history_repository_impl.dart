import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/journey_entity.dart';
import '../../domain/repositories/journey_history_repository.dart';

class JourneyHistoryRepositoryImpl implements JourneyHistoryRepository {
  final FirebaseFirestore _firestore;

  JourneyHistoryRepositoryImpl(this._firestore);

  @override
  Stream<List<JourneyEntity>> watchHistory(String uid) {
    return _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .collection(AppConstants.colJourneyHistory)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  JourneyEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return JourneyEntity(
      id: doc.id,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      startLocation: (data['startLocation'] as List<dynamic>? ?? [0.0, 0.0])
          .map((e) => (e as num).toDouble())
          .toList(),
      endLocation: (data['endLocation'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      status: data['status'] as String? ?? 'completed',
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

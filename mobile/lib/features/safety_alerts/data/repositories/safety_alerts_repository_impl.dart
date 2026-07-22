import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/safety_alert_entity.dart';
import '../../domain/repositories/safety_alerts_repository.dart';

class SafetyAlertsRepositoryImpl implements SafetyAlertsRepository {
  final FirebaseFirestore _firestore;

  SafetyAlertsRepositoryImpl(this._firestore);

  @override
  Stream<List<SafetyAlertEntity>> watchRecent({int limit = 5}) {
    return _firestore
        .collection(AppConstants.colSafetyAlerts)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  SafetyAlertEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SafetyAlertEntity(
      id: doc.id,
      title: data['title'] as String? ?? 'Safety Alert',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      severity: data['severity'] as String? ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

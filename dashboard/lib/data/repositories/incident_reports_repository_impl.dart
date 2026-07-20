import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../domain/entities/incident_entity.dart';
import '../../domain/repositories/incident_reports_repository.dart';

class IncidentReportsRepositoryImpl implements IncidentReportsRepository {
  final FirebaseFirestore _firestore;

  IncidentReportsRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.colIncidents);

  @override
  Stream<List<IncidentEntity>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<Result<void>> markResolved(String incidentId) async {
    try {
      // createdAt/updatedAt/resolvedAt are ISO-8601 strings across both
      // apps (set that way by mobile's report_incident_screen.dart) — must
      // stay a String here too, or mobile's IncidentModel.fromJson (which
      // does `json['updatedAt'] as String?`) throws a cast error reading it.
      final now = DateTime.now().toUtc().toIso8601String();
      await _collection.doc(incidentId).update({
        'status': 'RESOLVED',
        'updatedAt': now,
        'resolvedAt': now,
      });
      return const Success(null);
    } catch (e) {
      return Error('Failed to mark incident resolved: $e');
    }
  }

  IncidentEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return IncidentEntity(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      incidentType: data['incidentType'] as String? ?? 'OTHER',
      severity: data['severity'] as String? ?? 'MEDIUM',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: (data['location'] as List<dynamic>? ?? [0.0, 0.0])
          .map((e) => (e as num).toDouble())
          .toList(),
      address: data['address'] as String? ?? '',
      status: data['status'] as String? ?? 'PENDING',
      evidenceUrls:
          (data['evidenceUrls'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      assignedOfficerId: data['assignedOfficerId'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      aiClassification: data['aiClassification'] as String?,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now(),
      resolvedAt: data['resolvedAt'] != null ? DateTime.tryParse(data['resolvedAt'] as String) : null,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/incident_entity.dart';
import '../../domain/repositories/incident_repository.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final FirebaseFirestore _firestore;

  IncidentRepositoryImpl(this._firestore);

  @override
  String newIncidentId() => _firestore.collection(AppConstants.colIncidents).doc().id;

  @override
  Future<Result<void>> submitIncident(String id, IncidentEntity incident) async {
    try {
      await _firestore.collection(AppConstants.colIncidents).doc(id).set({
        'reporterId': incident.reporterId,
        'title': incident.title,
        'description': incident.description,
        'incidentType': incident.incidentType,
        'severity': incident.severity,
        'isAnonymous': incident.isAnonymous,
        'status': incident.status,
        'location': incident.location,
        'address': incident.address,
        'evidenceUrls': incident.evidenceUrls,
        'createdAt': incident.createdAt,
        'updatedAt': incident.updatedAt,
      });
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Stream<List<IncidentEntity>> watchMyReports(String uid, {int limit = 5}) {
    return _firestore
        .collection(AppConstants.colIncidents)
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  IncidentEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return IncidentEntity(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      incidentType: data['incidentType'] as String? ?? 'OTHER',
      severity: data['severity'] as String? ?? 'MEDIUM',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      status: data['status'] as String? ?? 'PENDING',
      location:
          (data['location'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? const [],
      address: data['address'] as String? ?? '',
      evidenceUrls: (data['evidenceUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      createdAt: data['createdAt'] as String? ?? '',
      updatedAt: data['updatedAt'] as String? ?? '',
    );
  }
}

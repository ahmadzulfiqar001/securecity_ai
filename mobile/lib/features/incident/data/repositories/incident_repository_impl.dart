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
}

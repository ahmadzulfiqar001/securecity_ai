import '../../../../core/errors/failures.dart';
import '../entities/incident_entity.dart';

abstract class IncidentRepository {
  /// Reserves a Firestore document id up front, so evidence can be uploaded
  /// to Storage under that id (`incidents/media/{uid}/{incidentId}/...`)
  /// before the incident document itself is written.
  String newIncidentId();

  Future<Result<void>> submitIncident(String id, IncidentEntity incident);
}

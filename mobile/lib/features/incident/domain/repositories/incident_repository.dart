import '../../../../core/errors/failures.dart';
import '../entities/incident_entity.dart';

abstract class IncidentRepository {
  /// Reserves a Firestore document id up front, so evidence can be uploaded
  /// to Storage under that id (`incidents/media/{uid}/{incidentId}/...`)
  /// before the incident document itself is written.
  String newIncidentId();

  Future<Result<void>> submitIncident(String id, IncidentEntity incident);

  /// The signed-in user's own reports, newest first - used by Home's
  /// "Recent Reports" section.
  Stream<List<IncidentEntity>> watchMyReports(String uid, {int limit = 5});
}

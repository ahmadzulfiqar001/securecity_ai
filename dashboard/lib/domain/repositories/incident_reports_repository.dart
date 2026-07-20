import '../../core/errors/result.dart';
import '../entities/incident_entity.dart';

abstract class IncidentReportsRepository {
  Stream<List<IncidentEntity>> watchAll();

  Future<Result<void>> markResolved(String incidentId);
}

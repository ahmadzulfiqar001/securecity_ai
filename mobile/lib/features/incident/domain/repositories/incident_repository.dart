import '../../../../core/errors/failures.dart';
import '../entities/incident_entity.dart';

abstract class IncidentRepository {
  Future<Result<void>> submitIncident(IncidentEntity incident);
}

import '../../../../core/errors/failures.dart';
import '../entities/sos_event_entity.dart';

abstract class SosRepository {
  /// Creates the SOS event and returns its Firestore document id, so the
  /// caller can later resolve it (e.g. "I am safe").
  Future<Result<String>> createSosEvent(SosEventEntity event);

  Future<Result<void>> resolveSosEvent(String eventId);
}

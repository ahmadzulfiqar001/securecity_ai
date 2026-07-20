import '../../core/errors/result.dart';
import '../entities/sos_event_entity.dart';

abstract class EmergencyQueueRepository {
  Stream<List<SosEventEntity>> watchActive();

  Future<Result<void>> acknowledge(String sosId, String authorityUid);
}

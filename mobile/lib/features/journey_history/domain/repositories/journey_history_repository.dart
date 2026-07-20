import '../entities/journey_entity.dart';

abstract class JourneyHistoryRepository {
  Stream<List<JourneyEntity>> watchHistory(String uid);
}

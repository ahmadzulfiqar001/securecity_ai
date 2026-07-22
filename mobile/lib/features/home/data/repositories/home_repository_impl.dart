import '../../domain/entities/safety_alert_entity.dart';
import '../../domain/entities/safety_score_entity.dart';
import '../../domain/repositories/home_repository.dart';

/// Currently a local/static data source — the dashboard's safety score and
/// alerts aren't wired to Firestore yet. Swapping this for a Firestore-
/// backed implementation later is a drop-in change: the domain contract
/// ([HomeRepository]) and presentation layer don't need to change.
class HomeRepositoryImpl implements HomeRepository {
  @override
  SafetyScoreEntity getCurrentZoneSafetyScore() {
    return SafetyScoreEntity(
      score: 85,
      label: 'High Safety Score',
      summary: 'Lighting is good. No active incidents within 1km reported recently.',
    );
  }

  @override
  List<SafetyAlertEntity> getRecentAlerts() {
    return [
      SafetyAlertEntity(
        title: 'Extreme Rainfall Alert',
        body: 'Urban flooding threat in Gulshan area. Avoid low-lying roads.',
        time: '10 mins ago',
        type: 'flood',
      ),
      SafetyAlertEntity(
        title: 'Road Blockage',
        body: 'Protest in Saddar causing heavy delays. Traffic diverted.',
        time: '1 hour ago',
        type: 'traffic',
      ),
    ];
  }
}

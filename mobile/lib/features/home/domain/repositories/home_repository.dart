import '../entities/safety_alert_entity.dart';
import '../entities/safety_score_entity.dart';

abstract class HomeRepository {
  SafetyScoreEntity getCurrentZoneSafetyScore();

  List<SafetyAlertEntity> getRecentAlerts();
}

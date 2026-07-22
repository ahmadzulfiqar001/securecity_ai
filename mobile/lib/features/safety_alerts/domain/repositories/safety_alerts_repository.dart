import '../entities/safety_alert_entity.dart';

abstract class SafetyAlertsRepository {
  /// Most recent broadcast alerts, newest first.
  Stream<List<SafetyAlertEntity>> watchRecent({int limit = 5});
}

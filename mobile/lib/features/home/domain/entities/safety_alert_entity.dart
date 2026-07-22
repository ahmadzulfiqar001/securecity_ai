/// A safety alert shown in Home's "Recent Safety Alerts" list.
class SafetyAlertEntity {
  final String title;
  final String body;
  final String time;
  final String type; // 'flood' | 'traffic' | ...

  SafetyAlertEntity({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
  });
}

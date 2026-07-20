/// Aggregate counts for the AI Command Center overview.
class DashboardStatsEntity {
  final int activeSosCount;
  final int incidentsTodayCount;
  final int totalIncidentsCount;
  final Map<String, int> incidentsByType;

  DashboardStatsEntity({
    required this.activeSosCount,
    required this.incidentsTodayCount,
    required this.totalIncidentsCount,
    required this.incidentsByType,
  });
}

import '../entities/dashboard_stats_entity.dart';

abstract class DashboardStatsRepository {
  Stream<DashboardStatsEntity> watchStats();
}

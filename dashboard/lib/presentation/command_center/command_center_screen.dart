import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/dashboard_stats_repository_impl.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_stats_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_tile.dart';

final dashboardStatsRepositoryProvider = Provider<DashboardStatsRepository>((ref) {
  return DashboardStatsRepositoryImpl(ref.watch(firestoreProvider));
});

final dashboardStatsStreamProvider = StreamProvider.autoDispose<DashboardStatsEntity>((ref) {
  return ref.watch(dashboardStatsRepositoryProvider).watchStats();
});

class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsStreamProvider);

    return statsAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, _) => AppErrorView(message: 'Failed to load overview: $error'),
      data: (stats) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Command Center',
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time overview across active emergencies and incident reports.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                final tiles = [
                  StatTile(
                    label: 'Active SOS Alerts',
                    value: '${stats.activeSosCount}',
                    icon: Icons.emergency_outlined,
                    accentColor: AppColors.emergencyRed,
                  ),
                  StatTile(
                    label: 'Incidents Today',
                    value: '${stats.incidentsTodayCount}',
                    icon: Icons.report_outlined,
                    accentColor: AppColors.warningAmber,
                  ),
                  StatTile(
                    label: 'Total Incidents',
                    value: '${stats.totalIncidentsCount}',
                    icon: Icons.description_outlined,
                    accentColor: AppColors.accentCyan,
                  ),
                  StatTile(
                    label: 'Incident Types Tracked',
                    value: '${stats.incidentsByType.length}',
                    icon: Icons.category_outlined,
                    accentColor: AppColors.successGreen,
                  ),
                ];
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    for (var i = 0; i < tiles.length; i++)
                      tiles[i]
                          .animate(delay: (i * 60).ms)
                          .fadeIn(duration: AppDurations.normal)
                          .slideY(begin: 0.15, end: 0, duration: AppDurations.normal),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incidents by Type',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: stats.incidentsByType.isEmpty
                        ? const AppEmptyView(
                            icon: Icons.bar_chart_outlined,
                            message: 'No incident reports yet.',
                          )
                        : _IncidentTypeChart(data: stats.incidentsByType),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: AppDurations.slow).slideY(begin: 0.1, end: 0, duration: AppDurations.slow),
          ],
        ),
      ),
    );
  }
}

class _IncidentTypeChart extends StatelessWidget {
  const _IncidentTypeChart({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY + 1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    entries[index].key,
                    style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  color: AppColors.accentCyan,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

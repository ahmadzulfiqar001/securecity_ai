import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/incident_reports_repository_impl.dart';
import '../../domain/entities/incident_entity.dart';
import '../../domain/repositories/incident_reports_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

final incidentReportsRepositoryProvider = Provider<IncidentReportsRepository>((ref) {
  return IncidentReportsRepositoryImpl(ref.watch(firestoreProvider));
});

final incidentReportsStreamProvider = StreamProvider.autoDispose<List<IncidentEntity>>((ref) {
  return ref.watch(incidentReportsRepositoryProvider).watchAll();
});

const _statusFilters = ['All', 'PENDING', 'RESOLVED'];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(incidentReportsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Citizen-submitted incident reports.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final status in _statusFilters)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: _statusFilter == status,
                  onSelected: (_) => setState(() => _statusFilter = status),
                  selectedColor: AppColors.glassCyan20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: reportsAsync.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => AppErrorView(message: 'Failed to load reports: $error'),
            data: (reports) {
              final filtered = _statusFilter == 'All'
                  ? reports
                  : reports.where((r) => r.status == _statusFilter).toList();

              if (filtered.isEmpty) {
                return const AppEmptyView(
                  icon: Icons.description_outlined,
                  message: 'No incident reports match this filter.',
                );
              }

              return GlassCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 96),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Severity')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Reported')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final report in filtered)
                          DataRow(
                            onSelectChanged: (_) => _showDetail(context, report),
                            cells: [
                              DataCell(Text(report.title.isEmpty ? '(untitled)' : report.title)),
                              DataCell(Text(report.incidentType)),
                              DataCell(_SeverityBadge(severity: report.severity)),
                              DataCell(_StatusBadge(status: report.status)),
                              DataCell(Text(DateFormat('MMM d, h:mm a').format(report.createdAt))),
                              DataCell(
                                report.status == 'RESOLVED'
                                    ? const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18)
                                    : TextButton(
                                        onPressed: () async {
                                          await ref
                                              .read(incidentReportsRepositoryProvider)
                                              .markResolved(report.id);
                                        },
                                        child: const Text('Mark Resolved'),
                                      ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, IncidentEntity report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title.isEmpty ? '(untitled)' : report.title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.description),
              const SizedBox(height: 12),
              Text('Address: ${report.address}', style: const TextStyle(color: AppColors.darkTextSecondary)),
              const SizedBox(height: 4),
              Text('Type: ${report.incidentType} · Severity: ${report.severity}',
                  style: const TextStyle(color: AppColors.darkTextSecondary)),
              const SizedBox(height: 4),
              Text('Evidence attachments: ${report.evidenceUrls.length}',
                  style: const TextStyle(color: AppColors.darkTextSecondary)),
              if (report.isAnonymous) ...[
                const SizedBox(height: 4),
                const Text('Reported anonymously', style: TextStyle(color: AppColors.darkTextSecondary)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'RESOLVED' ? AppColors.successGreen : AppColors.warningAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  Color get _color => switch (severity) {
        'CRITICAL' => AppColors.emergencyRed,
        'HIGH' => AppColors.emergencyOrange,
        'LOW' => AppColors.successGreen,
        _ => AppColors.warningAmber,
      };

  @override
  Widget build(BuildContext context) {
    return Text(severity, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600));
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/cards/glass_card.dart';
import '../../../incident/domain/entities/incident_entity.dart';

Color _statusColor(String status) => switch (status) {
      'RESOLVED' => AppColors.successGreen,
      'IN_PROGRESS' => AppColors.warningAmber,
      'REJECTED' => AppColors.emergencyRed,
      _ => AppColors.accentCyan, // PENDING and anything else
    };

/// One row in Home's "Recent Reports" section - the user's own incident
/// reports, newest first (see `IncidentRepository.watchMyReports`).
class RecentReportTile extends StatelessWidget {
  const RecentReportTile({super.key, required this.incident});

  final IncidentEntity incident;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(incident.status);

    return Semantics(
      label: '${incident.title}, status ${incident.status}',
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title.isEmpty ? incident.incidentType : incident.title,
                    style: AppTypography.darkTitleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(incident.incidentType, style: AppTypography.darkBodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                incident.status,
                style: AppTypography.darkLabelSmall.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

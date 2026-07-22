import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/cards/glass_card.dart';

class AlertItem extends StatelessWidget {
  const AlertItem({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
  });

  final String title;
  final String body;
  final String time;
  final String type;

  (IconData, Color) get _style => switch (type) {
        'flood' => (Icons.tsunami, AppColors.emergencyRed),
        'crime' => (Icons.local_police, AppColors.emergencyOrange),
        'traffic' => (Icons.traffic, AppColors.warningAmber),
        'weather' => (Icons.cloud_outlined, AppColors.infoBlue),
        _ => (Icons.notifications_active_outlined, AppColors.accentCyan),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;

    return Semantics(
      label: '$title, $time. $body',
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: AppTypography.darkTitleSmall)),
                      Text(time, style: AppTypography.darkLabelSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: AppTypography.darkBodySmall.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final icon = type == 'flood' ? Icons.tsunami : Icons.traffic;
    final color = type == 'flood' ? AppColors.emergencyRed : AppColors.warningAmber;

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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/motion.dart';
import '../../../../shared/cards/glass_card.dart';

/// Circular gauge summarizing the user's current-zone safety score.
class SafetyScoreCard extends StatelessWidget {
  const SafetyScoreCard({
    super.key,
    required this.score,
    required this.label,
    required this.summary,
  });

  final double score;
  final String label;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Current zone safety score: ${score.toStringAsFixed(0)} out of 100. $label. $summary',
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.glassWhite10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(score.toStringAsFixed(0), style: AppTypography.darkHeadlineSmall.copyWith(fontSize: 28)),
                    Text('/100', style: AppTypography.darkLabelMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Zone Safety', style: AppTypography.darkLabelMedium),
                  const SizedBox(height: 4),
                  Text(label, style: AppTypography.darkTitleMedium),
                  const SizedBox(height: 8),
                  Text(summary, style: AppTypography.darkBodySmall.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: motionDuration(context, AppDurations.slow)).slideY(begin: 0.1, end: 0);
  }
}

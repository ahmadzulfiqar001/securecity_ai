import 'package:flutter/material.dart';
import '../../app/theme/app_typography.dart';

/// Bold section title with an optional trailing action, used to introduce
/// grouped content on list-style screens (Quick Actions, Recent Alerts,
/// Nearby Services groups, etc.).
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: isDark ? AppTypography.darkTitleLarge : AppTypography.lightTitleLarge,
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

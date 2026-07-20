import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Shown for modules that are on the roadmap but not built yet. Every
/// sidebar item routes to something real — this, not a missing route or
/// fake data — is what an unbuilt module looks like.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.module, required this.icon});

  final String module;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.glassCyan10,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderCyan),
            ),
            child: Icon(icon, size: 48, color: AppColors.accentCyan),
          ),
          const SizedBox(height: 24),
          Text(
            module,
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This module is on the roadmap and not built yet.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

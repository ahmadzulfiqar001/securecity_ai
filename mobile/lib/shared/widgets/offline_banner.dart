import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/connectivity_providers.dart';
import '../../core/utils/motion.dart';

/// Thin persistent banner shown above the app's routed content whenever
/// [isOnlineProvider] reports no connectivity - mounted once in
/// `SecureCityApp`'s `MaterialApp.router(builder: ...)` so every screen
/// gets it for free instead of each one wiring up its own check.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return AnimatedSize(
      duration: motionDuration(context, AppDurations.fast),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isOnline
          ? const SizedBox(width: double.infinity)
          : Material(
              color: AppColors.warningAmber,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 16, color: AppColors.black),
                      const SizedBox(width: 8),
                      Text(
                        "You're offline - some features may not work.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

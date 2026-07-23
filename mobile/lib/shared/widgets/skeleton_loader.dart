import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// A single placeholder rectangle - the raw building block for skeleton
/// screens. Not shimmered on its own; wrap a tree of these in
/// [SkeletonListLoader] (or another `Shimmer.fromColors`) so the whole
/// layout animates as one surface instead of each box separately.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Content-shaped loading placeholder for the list/card screens that used
/// to show a bare [CircularProgressIndicator] - an icon-circle + two lines
/// per row, shaped like [GlassCard]. Falls back to a static (non-animated)
/// version when the platform's reduce-motion setting is on.
class SkeletonListLoader extends StatelessWidget {
  const SkeletonListLoader({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard;
    final highlightColor =
        brightness == Brightness.dark ? AppColors.darkCardElevated : AppColors.lightCardElevated;

    final rows = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const SkeletonBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox(width: 140, height: 14),
                        const SizedBox(height: 8),
                        SkeletonBox(width: MediaQuery.of(context).size.width * 0.4, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (MediaQuery.of(context).disableAnimations) return rows;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: AppDurations.shimmerDuration,
      child: rows,
    );
  }
}

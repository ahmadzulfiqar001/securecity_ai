import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Standard glassmorphic surface used across the dashboard for cards,
/// panels, and content containers — mirrors `mobile`'s `GlassCard`.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.variant = GlassCardVariant.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final GlassCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final decoration = switch (variant) {
      GlassCardVariant.surface => GlassDecoration.surfaceCard(borderRadius: borderRadius),
      GlassCardVariant.cyan => GlassDecoration.cyanCard(borderRadius: borderRadius),
      GlassCardVariant.emergency => GlassDecoration.emergencyCard(borderRadius: borderRadius),
    };

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}

enum GlassCardVariant { surface, cyan, emergency }

/// A floating glassmorphic panel that sits above page content (used for the
/// command palette and dropdown menus) — same visual language as
/// [GlassCard] but with heavier elevation.
class FloatingGlassPanel extends StatelessWidget {
  const FloatingGlassPanel({super.key, required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

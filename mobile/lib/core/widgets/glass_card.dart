import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Standard glassmorphic surface used across the app for cards, list tiles,
/// and content containers. Wraps [GlassDecoration.surfaceCard] so every
/// screen shares one card style instead of hand-rolling [BoxDecoration].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
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

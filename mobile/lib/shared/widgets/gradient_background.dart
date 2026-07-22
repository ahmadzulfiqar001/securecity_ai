import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Radial gradient backdrop - replaces the `AnimatedContainer` +
/// `RadialGradient` pattern duplicated in onboarding and SOS. Wrap a
/// screen's content with this instead of hand-rolling the gradient
/// `Positioned.fill` each time.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.accentColor = AppColors.accentCyan,
    this.intensity = 0.15,
    this.animate = true,
  });

  final Widget child;
  final Color accentColor;
  final double intensity;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.2,
        colors: [accentColor.withValues(alpha: intensity), AppColors.darkBackground],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: animate
              ? AnimatedContainer(duration: const Duration(milliseconds: 500), decoration: decoration)
              : DecoratedBox(decoration: decoration),
        ),
        child,
      ],
    );
  }
}

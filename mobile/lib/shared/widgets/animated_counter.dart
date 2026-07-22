import 'package:flutter/material.dart';

/// Animates a number counting up (or down) to [value] instead of jumping
/// straight to it - e.g. a safety score gauge filling in on first paint.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.decimals = 0,
  });

  final double value;
  final Duration duration;
  final TextStyle? style;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(animatedValue.toStringAsFixed(decimals), style: style);
      },
    );
  }
}

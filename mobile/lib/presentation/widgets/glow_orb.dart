import 'package:flutter/material.dart';

/// Decorative blurred glow circle used behind splash/auth/home screens for
/// the app's signature glassmorphism background. Extracted from the
/// `Positioned > Container(shape: circle, boxShadow: [...])` pattern that
/// was previously duplicated in every screen that used it.
class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    required this.color,
    required this.size,
    required this.blurRadius,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final Color color;
  final double size;
  final double blurRadius;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color, blurRadius: blurRadius)],
          ),
        ),
      ),
    );
  }
}

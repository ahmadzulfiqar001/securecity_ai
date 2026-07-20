import 'package:flutter/material.dart';

/// Layout breakpoints and small `BuildContext` helpers used to keep
/// content readable on tablets/foldables instead of stretching
/// phone-oriented layouts edge-to-edge.
abstract final class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

extension ResponsiveContext on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  bool get isTablet => _width >= AppBreakpoints.tablet;

  bool get isDesktop => _width >= AppBreakpoints.desktop;

  /// Number of grid columns for card/quick-action grids: 2 on phones,
  /// 3 on tablets, 4 on desktop-width windows.
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }
}

/// Caps the width of long-form content (forms, auth screens) on wide
/// viewports and centers it, so a tablet doesn't stretch a login form
/// across the full screen width.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

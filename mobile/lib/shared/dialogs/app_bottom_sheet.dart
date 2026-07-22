import 'package:flutter/material.dart';

/// Shows a themed modal bottom sheet (styling comes from the global
/// `bottomSheetTheme` - rounded top corners, drag handle). Named
/// `AppBottomSheet` rather than `BottomSheet` to avoid shadowing Flutter's
/// own [BottomSheet] widget.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}

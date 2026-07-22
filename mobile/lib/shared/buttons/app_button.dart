import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum AppButtonVariant { primary, outlined, text }

/// Primary reusable button with a built-in loading state - replaces the
/// hand-rolled `SizedBox(child: CircularProgressIndicator())` swap that was
/// duplicated across login, register, and report-incident submit buttons.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final spinnerColor = variant == AppButtonVariant.primary
        ? AppColors.primaryDeepBlue
        : AppColors.accentCyan;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: spinnerColor, strokeWidth: 2),
          )
        : Text(label);

    return switch (variant) {
      AppButtonVariant.primary => icon == null || isLoading
          ? ElevatedButton(onPressed: onTap, child: child)
          : ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label)),
      AppButtonVariant.outlined => icon == null || isLoading
          ? OutlinedButton(onPressed: onTap, child: child)
          : OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label)),
      AppButtonVariant.text => TextButton(onPressed: onTap, child: child),
    };
  }
}

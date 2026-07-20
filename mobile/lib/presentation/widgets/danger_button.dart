import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Full-width destructive/emergency action button (sign out, delete,
/// cancel SOS). Extracted from the `ElevatedButton.styleFrom(backgroundColor:
/// AppColors.emergencyRed, ...)` override duplicated wherever a destructive
/// action was needed.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: AppColors.emergencyRed,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

    if (icon == null) {
      return ElevatedButton(onPressed: onPressed, style: style, child: Text(label));
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, color: AppColors.white),
      label: Text(label),
    );
  }
}

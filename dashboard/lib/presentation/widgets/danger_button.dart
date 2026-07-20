import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Destructive/emergency action button (delete zone, resolve-as-false-alarm,
/// remove camera) — ported from `mobile/lib/presentation/widgets/danger_button.dart`
/// for parity across both apps.
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

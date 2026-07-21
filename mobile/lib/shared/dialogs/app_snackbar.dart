import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Shared error/success snackbar, replacing the `_showErrorSnackbar` helper
/// that was previously copy-pasted verbatim across `login_screen.dart`,
/// `register_screen.dart`, and the ad hoc `SnackBar`s in
/// `report_incident_screen.dart`/`map_screen.dart`/`emergency_contacts_screen.dart`.
abstract final class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(context, message: message, color: AppColors.emergencyRed, icon: Icons.error_outline);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, color: AppColors.successGreen, icon: Icons.check_circle_outline);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(icon, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

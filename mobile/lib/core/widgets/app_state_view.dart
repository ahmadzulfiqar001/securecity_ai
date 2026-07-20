import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Centered spinner for the loading branch of a `StreamProvider`/`FutureProvider`
/// `.when()`. Shared across every Firestore-backed screen instead of each
/// screen building its own `Center(child: CircularProgressIndicator())`.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentCyan),
    );
  }
}

/// Centered "nothing here yet" state with an icon and message, for the empty
/// branch of a list/stream (no journeys, no contacts, no safety data, etc.).
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = isDark ? AppTypography.darkBodyMedium : AppTypography.lightBodyMedium;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.darkTextDisabled),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: textStyle),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered error state with a retry action, for the error branch of a
/// `.when()` on a `StreamProvider`/`FutureProvider`.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = isDark ? AppTypography.darkBodyMedium : AppTypography.lightBodyMedium;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.emergencyRed),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(color: AppColors.emergencyRed),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

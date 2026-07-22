import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Centered error state with a retry action, for the error branch of a
/// `.when()` on a `StreamProvider`/`FutureProvider`.
class ErrorState extends StatelessWidget {
  const ErrorState({
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

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Centered spinner for the loading branch of a `StreamProvider`/`FutureProvider`
/// `.when()`. Shared across every Firestore-backed screen instead of each
/// screen building its own `Center(child: CircularProgressIndicator())`.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentCyan),
    );
  }
}

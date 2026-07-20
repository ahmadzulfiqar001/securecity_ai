import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';

/// Shown when a signed-in user's `role` claim isn't an authority role
/// (CITIZEN, or the claim hasn't propagated yet). This dashboard is
/// authority-only — `firestore.rules`' `isAuthority()` would reject their
/// reads anyway, so this is a clear message instead of a confusing blank
/// screen or a silent redirect loop.
class AccessRestrictedScreen extends ConsumerWidget {
  const AccessRestrictedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.emergencyRed),
              const SizedBox(height: 24),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This dashboard is for Police, Fire, Ambulance, Traffic, and\n'
                'Administration accounts only. Your account does not have\n'
                'an authority role assigned.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkTextSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => ref.read(firebaseAuthProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

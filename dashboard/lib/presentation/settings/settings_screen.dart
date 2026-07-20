import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final roleAsync = ref.watch(currentRoleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Email', value: user?.email ?? '—'),
              const SizedBox(height: 12),
              _InfoRow(label: 'Role', value: roleAsync.value ?? '—'),
              const SizedBox(height: 12),
              _InfoRow(label: 'User ID', value: user?.uid ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(firebaseAuthProvider).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary)),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.darkTextPrimary))),
      ],
    );
  }
}

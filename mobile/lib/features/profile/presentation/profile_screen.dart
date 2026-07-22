import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers/session_providers.dart';
import '../../../shared/buttons/emergency_button.dart';
import '../../../shared/widgets/avatar.dart';
import 'widgets/profile_menu_item.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Avatar(radius: 54),
              const SizedBox(height: 24),
              Text(user?.fullName ?? 'Citizen', style: AppTypography.darkTitleLarge),
              const SizedBox(height: 8),
              Text(user?.email ?? '', style: AppTypography.darkBodyMedium),
              const SizedBox(height: 48),
              ProfileMenuItem(
                title: 'Emergency Contacts',
                icon: Icons.contact_phone_outlined,
                onTap: () => context.push(AppRoutes.emergencyContacts),
              ),
              ProfileMenuItem(
                title: 'Journey History',
                icon: Icons.history,
                onTap: () => context.push(AppRoutes.journeyHistory),
              ),
              ProfileMenuItem(
                title: 'Settings',
                icon: Icons.settings_outlined,
                onTap: () => context.push(AppRoutes.settings),
              ),
              const Spacer(),
              EmergencyButton(
                label: 'Sign Out',
                icon: Icons.logout,
                onPressed: () async {
                  await ref.read(signOutProvider)();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

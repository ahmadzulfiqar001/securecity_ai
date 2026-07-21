import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/shake_detector.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/buttons/danger_button.dart';
import '../../../shared/widgets/glow_orb.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../map/presentation/providers/map_providers.dart';
import 'widgets/alert_item.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/safety_score_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Bottom-nav position: only 0 (Home) and 4 (Profile) render in place —
  /// Map/SOS/Chat (1-3) are pushed as full routes and never change this,
  /// so the bar doesn't visually "stick" on them after the user returns.
  int _currentIndex = 0;

  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    _maybeStartShakeDetection();
  }

  void _maybeStartShakeDetection() {
    final enabled = ref.read(storageServiceProvider).getShakeDetectionEnabled();
    if (!enabled) return;
    _shakeDetector = ShakeDetector(
      onShake: () {
        if (mounted) context.push(AppRoutes.sos);
      },
    )..startListening();
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  void _onNavTap(int index) {
    switch (index) {
      case 1:
        context.push(AppRoutes.map);
      case 2:
        context.push(AppRoutes.sos);
      case 3:
        context.push(AppRoutes.chatbot);
      default:
        setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps client-side geofence monitoring (features/map/presentation/providers/map_providers.dart)
    // alive for as long as the user is signed in and on the home screen.
    ref.watch(geofenceMonitorProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          GlowOrb(
            top: -150,
            left: -150,
            size: 350,
            blurRadius: 120,
            color: AppColors.accentCyan.withValues(alpha: 0.1),
          ),
          _currentIndex == 4 ? const _ProfileTab() : const _HomeTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.glassWhite10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Safety Map',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyRed,
                  boxShadow: [BoxShadow(color: AppColors.emergencyRed, blurRadius: 8, spreadRadius: 1)],
                ),
                child: const Icon(Icons.sos, color: AppColors.primaryDeepBlue, size: 28),
              ),
              label: 'SOS',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'AI Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?.fullName ?? 'Citizen';
    final columns = context.gridColumns;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Greeting & Notifications icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assalam-o-Alaikum,', style: AppTypography.darkLabelMedium),
                  Text(userName, style: AppTypography.darkHeadlineSmall.copyWith(fontSize: 24)),
                ],
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassWhite10),
                  ),
                  child: const Icon(Icons.notifications_outlined),
                ),
                tooltip: 'Notifications',
                onPressed: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const SafetyScoreCard(
            score: 85,
            label: 'High Safety Score',
            summary: 'Lighting is good. No active incidents within 1km reported recently.',
          ),
          const SizedBox(height: 32),

          Text('Quick Safety Actions', style: AppTypography.darkTitleMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              QuickActionCard(
                title: 'Report Incident',
                subtitle: 'Submit evidence',
                icon: Icons.add_moderator_outlined,
                color: AppColors.accentCyan,
                onTap: () => context.push(AppRoutes.incidentReport),
              ),
              QuickActionCard(
                title: 'Safe Navigation',
                subtitle: 'Avoid risk areas',
                icon: Icons.navigation_outlined,
                color: AppColors.successGreen,
                onTap: () => context.push(AppRoutes.map),
              ),
              QuickActionCard(
                title: 'Nearby Services',
                subtitle: 'Hospitals & Police',
                icon: Icons.local_hospital_outlined,
                color: AppColors.infoBlue,
                onTap: () => context.push(AppRoutes.nearbyServices),
              ),
              QuickActionCard(
                title: 'Area Safety',
                subtitle: 'Check history',
                icon: Icons.location_history_outlined,
                color: AppColors.warningAmber,
                onTap: () => context.push(AppRoutes.areaSafety),
              ),
            ],
          ).animate().fadeIn(delay: AppDurations.fast, duration: AppDurations.slow),
          const SizedBox(height: 32),

          Text('Recent Safety Alerts', style: AppTypography.darkTitleMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          const AlertItem(
            title: 'Extreme Rainfall Alert',
            body: 'Urban flooding threat in Gulshan area. Avoid low-lying roads.',
            time: '10 mins ago',
            type: 'flood',
          ),
          const AlertItem(
            title: 'Road Blockage',
            body: 'Protest in Saddar causing heavy delays. Traffic diverted.',
            time: '1 hour ago',
            type: 'traffic',
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('My Profile', style: AppTypography.darkHeadlineSmall),
            const SizedBox(height: 32),
            const CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.glassCyan20,
              child: Icon(Icons.person, size: 64, color: AppColors.accentCyan),
            ),
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
            DangerButton(
              label: 'Sign Out',
              icon: Icons.logout,
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

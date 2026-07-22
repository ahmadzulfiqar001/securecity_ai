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
import '../../../core/providers/session_providers.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/glow_orb.dart';
import '../../map/presentation/providers/map_providers.dart';
import 'providers/home_providers.dart';
import 'widgets/alert_item.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/safety_score_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
        context.push(AppRoutes.chat);
      case 4:
        context.push(AppRoutes.profile);
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
          const _HomeTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.glassWhite10, width: 1)),
        ),
        child: BottomNavigationBar(
          // Home (index 0) is the only tab that ever renders in place -
          // Map/SOS/Chat/Profile are pushed as full routes, so the bar
          // always shows Home selected rather than "sticking" on whichever
          // was tapped last.
          currentIndex: 0,
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
    final user = ref.watch(currentUserProvider);
    final userName = user?.fullName ?? 'Citizen';
    final columns = context.gridColumns;
    final safetyScore = ref.watch(safetyScoreProvider);
    final recentAlerts = ref.watch(recentAlertsProvider);

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

          SafetyScoreCard(
            score: safetyScore.score,
            label: safetyScore.label,
            summary: safetyScore.summary,
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
                onTap: () => context.push(AppRoutes.services),
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
          for (final alert in recentAlerts)
            AlertItem(
              title: alert.title,
              body: alert.body,
              time: alert.time,
              type: alert.type,
            ),
        ],
      ),
    );
  }
}

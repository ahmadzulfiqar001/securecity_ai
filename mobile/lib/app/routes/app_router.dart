import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_routes.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/auth/presentation/register/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/incident/presentation/report_incident_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/emergency_contacts/presentation/emergency_contacts_screen.dart';
import '../../features/journey_history/presentation/journey_history_screen.dart';
import '../../features/nearby_services/presentation/nearby_services_screen.dart';
import '../../features/area_safety/presentation/area_safety_screen.dart';

/// Bridges a [Stream] (Firebase's `authStateChanges()`) to a [Listenable]
/// so GoRouter re-evaluates `redirect` whenever auth state changes —
/// without this, signing out on a protected screen wouldn't redirect
/// until the next explicit navigation.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
    redirect: (BuildContext context, GoRouterState state) {
      final user = firebaseAuth.currentUser;
      final loggedIn = user != null;
      final goingToAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding;

      // If not logged in and trying to go to protected pages, redirect to login
      if (!loggedIn && !goingToAuth) {
        return AppRoutes.login;
      }

      // If logged in and trying to access auth pages, redirect to home
      if (loggedIn &&
          (state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register)) {
        return AppRoutes.home;
      }

      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.emergencyRed),
                const SizedBox(height: 16),
                Text('Page not found', style: AppTypography.darkTitleLarge),
                const SizedBox(height: 8),
                Text(
                  state.uri.toString(),
                  style: AppTypography.darkBodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.sos,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SosScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (BuildContext context, GoRouterState state) {
          return const MapScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        builder: (BuildContext context, GoRouterState state) {
          return const ChatbotScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (BuildContext context, GoRouterState state) {
          return const NotificationsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.incidentReport,
        builder: (BuildContext context, GoRouterState state) {
          return const ReportIncidentScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.emergencyContacts,
        builder: (BuildContext context, GoRouterState state) {
          return const EmergencyContactsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.journeyHistory,
        builder: (BuildContext context, GoRouterState state) {
          return const JourneyHistoryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.nearbyServices,
        builder: (BuildContext context, GoRouterState state) {
          return const NearbyServicesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.areaSafety,
        builder: (BuildContext context, GoRouterState state) {
          return const AreaSafetyScreen();
        },
      ),
    ],
  );
});

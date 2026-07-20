import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/auth/presentation/register/register_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/sos/sos_screen.dart';
import '../../presentation/map/map_screen.dart';
import '../../presentation/chatbot/chatbot_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/incident/report_incident_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../features/emergency_contacts/presentation/emergency_contacts_screen.dart';
import '../../presentation/journey_history/journey_history_screen.dart';
import '../../presentation/nearby_services/nearby_services_screen.dart';
import '../../presentation/area_safety/area_safety_screen.dart';

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
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
    redirect: (BuildContext context, GoRouterState state) {
      final user = firebaseAuth.currentUser;
      final loggedIn = user != null;
      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      // If not logged in and trying to go to protected pages, redirect to login
      if (!loggedIn && !goingToAuth) {
        return '/login';
      }

      // If logged in and trying to access auth pages, redirect to home
      if (loggedIn &&
          (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/home';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/sos',
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
        path: '/map',
        builder: (BuildContext context, GoRouterState state) {
          return const MapScreen();
        },
      ),
      GoRoute(
        path: '/chatbot',
        builder: (BuildContext context, GoRouterState state) {
          return const ChatbotScreen();
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (BuildContext context, GoRouterState state) {
          return const NotificationsScreen();
        },
      ),
      GoRoute(
        path: '/incident/report',
        builder: (BuildContext context, GoRouterState state) {
          return const ReportIncidentScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: '/emergency-contacts',
        builder: (BuildContext context, GoRouterState state) {
          return const EmergencyContactsScreen();
        },
      ),
      GoRoute(
        path: '/journey-history',
        builder: (BuildContext context, GoRouterState state) {
          return const JourneyHistoryScreen();
        },
      ),
      GoRoute(
        path: '/nearby-services',
        builder: (BuildContext context, GoRouterState state) {
          return const NearbyServicesScreen();
        },
      ),
      GoRoute(
        path: '/area-safety',
        builder: (BuildContext context, GoRouterState state) {
          return const AreaSafetyScreen();
        },
      ),
    ],
  );
});

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_routes.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/authentication/presentation/login/login_screen.dart';
import '../../features/authentication/presentation/register/register_screen.dart';
import '../../features/authentication/presentation/forgot_password/forgot_password_screen.dart';
import '../../features/authentication/presentation/verify_email/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/chat/presentation/chatbot_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/incident/presentation/report_incident_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/medical_info_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/emergency_contacts/presentation/emergency_contacts_screen.dart';
import '../../features/journey_history/presentation/journey_history_screen.dart';
import '../../features/services/presentation/nearby_services_screen.dart';
import '../../features/area_safety/presentation/area_safety_screen.dart';

/// Bridges a [Stream] (Firebase's `authStateChanges()`) to a [Listenable]
/// so GoRouter re-evaluates `redirect` whenever auth state changes -
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
  final analytics = ref.watch(firebaseAnalyticsProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
    observers: [FirebaseAnalyticsObserver(analytics: analytics)],
    redirect: (BuildContext context, GoRouterState state) {
      final user = firebaseAuth.currentUser;
      final loggedIn = user != null;
      final matched = state.matchedLocation;

      final isLoginOrRegister = matched == AppRoutes.login || matched == AppRoutes.register;
      final isPreAuthPage = matched == AppRoutes.splash || matched == AppRoutes.onboarding;
      final isForgotPassword = matched == AppRoutes.forgotPassword;
      final isVerifyEmailPage = matched == AppRoutes.verifyEmail;

      // Not logged in: only the auth / pre-auth pages are reachable.
      if (!loggedIn) {
        final reachableWhileLoggedOut = isLoginOrRegister || isPreAuthPage || isForgotPassword;
        return reachableWhileLoggedOut ? null : AppRoutes.login;
      }

      // Logged in but the email isn't verified yet: confined to the Verify
      // Email page (matches Splash → Check Login → Email Verified? → Home).
      if (!user.emailVerified) {
        final reachableWhileUnverified = isVerifyEmailPage || isPreAuthPage || isForgotPassword;
        return reachableWhileUnverified ? null : AppRoutes.verifyEmail;
      }

      // Logged in and verified: bounce away from auth / pending-verification pages.
      if (isLoginOrRegister || isVerifyEmailPage) {
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
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        builder: (BuildContext context, GoRouterState state) {
          return const VerifyEmailScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.sos,
        name: 'sos',
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
        name: 'map',
        builder: (BuildContext context, GoRouterState state) {
          return const MapScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (BuildContext context, GoRouterState state) {
          return const ChatbotScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (BuildContext context, GoRouterState state) {
          return const NotificationsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.incidentReport,
        name: 'incidentReport',
        builder: (BuildContext context, GoRouterState state) {
          return const ReportIncidentScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.medicalInfo,
        name: 'medicalInfo',
        builder: (BuildContext context, GoRouterState state) {
          return const MedicalInfoScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.emergencyContacts,
        name: 'emergencyContacts',
        builder: (BuildContext context, GoRouterState state) {
          return const EmergencyContactsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.journeyHistory,
        name: 'journeyHistory',
        builder: (BuildContext context, GoRouterState state) {
          return const JourneyHistoryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.services,
        name: 'services',
        builder: (BuildContext context, GoRouterState state) {
          return const NearbyServicesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.areaSafety,
        name: 'areaSafety',
        builder: (BuildContext context, GoRouterState state) {
          return const AreaSafetyScreen();
        },
      ),
    ],
  );
});

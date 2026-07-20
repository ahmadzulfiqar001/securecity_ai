import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/shell/dashboard_shell.dart';
import '../../presentation/command_center/command_center_screen.dart';
import '../../presentation/emergency_queue/emergency_queue_screen.dart';
import '../../presentation/reports/reports_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/computer_vision/computer_vision_screen.dart';
import '../../presentation/interactive_map/interactive_map_screen.dart';
import '../../presentation/crime_heatmap/crime_heatmap_screen.dart';
import '../../presentation/zone_manager/zone_manager_screen.dart';
import '../../presentation/placeholder/placeholder_screen.dart';

/// Bridges a [Stream] to a [Listenable] so GoRouter re-evaluates `redirect`
/// on every auth state change — same pattern as `mobile`'s
/// `GoRouterRefreshStream`.
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
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
    // Only the coarse signed-in/signed-out split happens here — it's
    // synchronous-friendly via the cached auth state. Whether the signed-in
    // user's *role* is actually an authority role is checked inside
    // DashboardShell (async, via currentRoleProvider), not here — trying to
    // await an async claims fetch inside `redirect` fights GoRouter's API
    // for no real benefit, since Firestore itself re-enforces the same rule
    // server-side regardless.
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = firebaseAuth.currentUser != null;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            DashboardShell(currentLocation: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (context, state) => const CommandCenterScreen()),
          GoRoute(
            path: '/emergency-queue',
            builder: (context, state) => const EmergencyQueueScreen(),
          ),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(
            path: '/map',
            builder: (context, state) => const InteractiveMapScreen(),
            routes: <RouteBase>[
              GoRoute(path: 'zones', builder: (context, state) => const ZoneManagerScreen()),
            ],
          ),
          GoRoute(
            path: '/crime-heatmap',
            builder: (context, state) => const CrimeHeatmapScreen(),
          ),
          GoRoute(
            path: '/computer-vision',
            builder: (context, state) => const ComputerVisionScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const PlaceholderScreen(
              module: 'Analytics',
              icon: Icons.bar_chart_outlined,
            ),
          ),
          GoRoute(
            path: '/ai-predictions',
            builder: (context, state) => const PlaceholderScreen(
              module: 'AI Predictions',
              icon: Icons.psychology_outlined,
            ),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const PlaceholderScreen(
              module: 'Users',
              icon: Icons.people_outline,
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const PlaceholderScreen(
              module: 'Notifications',
              icon: Icons.notifications_outlined,
            ),
          ),
          GoRoute(
            path: '/system-logs',
            builder: (context, state) => const PlaceholderScreen(
              module: 'System Logs',
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      ),
    ],
  );
});

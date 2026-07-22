import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../features/settings/presentation/providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Shown instead of [SecureCityApp] when `Firebase.initializeApp()` fails -
/// every provider in this app assumes a live Firebase app, so building the
/// real widget tree would crash immediately without this guard.
class FirebaseNotConfiguredApp extends StatelessWidget {
  const FirebaseNotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 56, color: AppColors.warningAmber),
                SizedBox(height: 24),
                Text(
                  'Firebase Not Configured',
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Run `flutterfire configure` in mobile/ to connect this app\n'
                  'to the SecureCity AI Firebase project, then restart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkTextSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecureCityApp extends ConsumerWidget {
  const SecureCityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Notification Service on app startup
    try {
      ref.read(notificationServiceProvider).initialize();
    } catch (e) {
      debugPrint('Notification Service initialization skipped: $e');
    }

    return MaterialApp.router(
      title: 'SecureCity AI',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

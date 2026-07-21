import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/app_providers.dart';
import 'features/settings/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI status bar styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Firebase. Every provider in this app assumes a live Firebase
  // app (FirebaseAuth.instance, FirebaseFirestore.instance, etc. throw
  // `[core/no-app]` otherwise) — if `flutterfire configure` hasn't been run
  // yet, building the real widget tree would crash immediately, so show a
  // clear instruction screen instead of the app.
  var firebaseReady = true;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    firebaseReady = false;
  }

  runApp(
    firebaseReady
        ? ProviderScope(
            overrides: [
              // Inject SharedPreferences into the provider
              sharedPreferencesProvider.overrideWithValue(sharedPrefs),
            ],
            child: const SecureCityApp(),
          )
        : const _FirebaseNotConfiguredApp(),
  );
}

class _FirebaseNotConfiguredApp extends StatelessWidget {
  const _FirebaseNotConfiguredApp();

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

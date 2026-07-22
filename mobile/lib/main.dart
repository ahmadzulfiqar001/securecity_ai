import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers/app_providers.dart';

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
  // `[core/no-app]` otherwise) - if `flutterfire configure` hasn't been run
  // yet, building the real widget tree would crash immediately, so show a
  // clear instruction screen instead of the app.
  var firebaseReady = true;
  try {
    await Firebase.initializeApp();

    // Crashlytics: route every uncaught Flutter/Dart error to Firebase so
    // crashes in the field are visible instead of silently dropped.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Remote Config: best-effort fetch - a slow/offline fetch must not block
    // app startup, so failures just leave the SDK's compiled-in defaults.
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config fetch skipped: $e');
    }
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
        : const FirebaseNotConfiguredApp(),
  );
}

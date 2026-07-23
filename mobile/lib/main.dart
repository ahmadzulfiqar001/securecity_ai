import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers/app_providers.dart';

/// Runs in a separate background isolate when a push arrives while the app
/// is backgrounded or killed. The OS already displays messages that carry
/// a `notification` payload with no code needed - this only matters for
/// data-only messages, which nothing in this app sends today (there's no
/// backend to send any push at all yet), but is the correct place to
/// handle them once one exists, so it's wired up now rather than being a
/// silent gap.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM message received: ${message.messageId}');
}

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

    // Must be registered before runApp() so the background isolate picks
    // it up even if the app is killed shortly after this call returns.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // App Check: Firebase AI Logic (features/chat's Gemini integration)
    // rejects calls without it. Using the debug providers for now, which
    // work immediately in development - on first run each prints a debug
    // token to the device log that must be registered once in Firebase
    // Console -> App Check -> "Manage debug tokens". Before a real release
    // build, switch providerAndroid to const AndroidPlayIntegrityProvider()
    // and providerApple to const AppleDeviceCheckProvider() (or
    // AppleAppAttestProvider()).
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
    } catch (e) {
      debugPrint('App Check activation skipped: $e');
    }

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

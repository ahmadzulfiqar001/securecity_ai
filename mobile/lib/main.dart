import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
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
        : const FirebaseNotConfiguredApp(),
  );
}

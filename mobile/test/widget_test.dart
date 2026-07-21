import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securecity_ai/app/app.dart';
import 'package:securecity_ai/core/providers/app_providers.dart';

void main() {
  testWidgets('SecureCityApp builds without throwing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        ],
        child: const SecureCityApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    // SplashScreen holds a 3s Future.delayed before navigating, and the next
    // screen runs flutter_animate entrance animations — settle both so no
    // Timer is left pending at teardown.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}

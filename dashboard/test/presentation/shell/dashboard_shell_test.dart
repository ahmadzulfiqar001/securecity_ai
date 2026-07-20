import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_dashboard/core/providers/app_providers.dart';
import 'package:securecity_dashboard/presentation/shell/dashboard_shell.dart';

void main() {
  Widget buildApp({required String role, required Widget child}) {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-uid', customClaim: {'role': role}),
      signedIn: true,
    );

    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      ],
      child: MaterialApp(home: DashboardShell(currentLocation: '/', child: child)),
    );
  }

  testWidgets('CITIZEN role sees Access Restricted, not the dashboard', (tester) async {
    await tester.pumpWidget(buildApp(role: 'CITIZEN', child: const Text('PAGE CONTENT')));
    await tester.pumpAndSettle();

    expect(find.text('Access Restricted'), findsOneWidget);
    expect(find.text('PAGE CONTENT'), findsNothing);
  });

  testWidgets('POLICE role sees the sidebar and the routed page content', (tester) async {
    // The sidebar collapses to an icon rail below AppConstants.responsiveBreakpoint
    // (900px) — the default 800x600 test surface would trigger that collapsed
    // state, hiding the nav labels this test asserts on. Use a desktop-width
    // viewport so the sidebar renders expanded, matching real dashboard usage.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(role: 'POLICE', child: const Text('PAGE CONTENT')));
    await tester.pumpAndSettle();

    expect(find.text('Access Restricted'), findsNothing);
    expect(find.text('AI Command Center'), findsOneWidget);
    expect(find.text('Emergency Queue'), findsOneWidget);
    expect(find.text('PAGE CONTENT'), findsOneWidget);
  });
}

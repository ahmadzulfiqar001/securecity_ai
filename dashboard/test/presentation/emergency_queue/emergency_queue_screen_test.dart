import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_dashboard/core/providers/app_providers.dart';
import 'package:securecity_dashboard/presentation/emergency_queue/emergency_queue_screen.dart';

void main() {
  testWidgets('shows an active SOS alert and removes it after acknowledging', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('sos_events').add({
      'userId': 'citizen-1',
      'status': 'ACTIVE',
      'location': [67.0011, 24.8607],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'officer-1', customClaim: {'role': 'POLICE'}),
      signedIn: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: Scaffold(body: EmergencyQueueScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('citizen-1'), findsOneWidget);
    expect(find.text('No active SOS alerts.'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Acknowledge'));
    await tester.pumpAndSettle();

    expect(find.textContaining('citizen-1'), findsNothing);
    expect(find.text('No active SOS alerts.'), findsOneWidget);
  });
}

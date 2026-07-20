import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_ai/core/providers/app_providers.dart';
import 'package:securecity_ai/presentation/emergency_contacts/emergency_contacts_screen.dart';

void main() {
  testWidgets('adding a contact shows it in the list', (WidgetTester tester) async {
    const uid = 'test-uid';
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'id': uid,
      'firebaseUid': uid,
      'emergencyContacts': <Map<String, dynamic>>[],
    });

    final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: EmergencyContactsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No emergency contacts yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Ayesha Khan');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '+923001234567');
    await tester.enterText(find.widgetWithText(TextFormField, 'Relationship'), 'Sister');

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.textContaining('Sister'), findsOneWidget);
    expect(find.textContaining('No emergency contacts yet'), findsNothing);
  });
}

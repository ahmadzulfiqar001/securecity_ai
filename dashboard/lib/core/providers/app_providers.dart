import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Talks only to cv_engine — see core/network/api_client.dart.
final cvEngineDioProvider = Provider<Dio>((ref) => createCvEngineDio());

/// Talks only to ai_engine (Crime Heatmap / Safe Route / Safety Score).
final aiEngineDioProvider = Provider<Dio>((ref) => createAiEngineDio());

/// Live auth state — the router's `refreshListenable` and the auth guard
/// both key off this so sign-in/sign-out is reflected immediately.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// The signed-in user's `role` custom claim (POLICE/AMBULANCE/FIRE/ADMIN/
/// CITIZEN), set by `functions/src/index.ts` — never client-writable. Null
/// when signed out or the claim hasn't propagated yet.
final currentRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return null;
  final tokenResult = await user.getIdTokenResult();
  return tokenResult.claims?['role'] as String?;
});

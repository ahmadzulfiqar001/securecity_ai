import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/emergency_contacts_repository_impl.dart';
import '../../../../core/entities/emergency_contact_entity.dart';
import '../../domain/repositories/emergency_contacts_repository.dart';

final emergencyContactsRepositoryProvider = Provider<EmergencyContactsRepository>((ref) {
  return EmergencyContactsRepositoryImpl(ref.watch(firestoreProvider));
});

final emergencyContactsStreamProvider =
    StreamProvider.autoDispose<List<EmergencyContactEntity>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(emergencyContactsRepositoryProvider).watchContacts(uid);
});

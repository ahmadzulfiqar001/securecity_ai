import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../domain/entities/incident_entity.dart';
import '../../domain/repositories/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepositoryImpl(ref.watch(firestoreProvider));
});

/// The signed-in user's own recent reports - used by Home's "Recent
/// Reports" section.
final myRecentReportsProvider = StreamProvider.autoDispose<List<IncidentEntity>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(incidentRepositoryProvider).watchMyReports(uid);
});

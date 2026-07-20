import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/journey_history_repository_impl.dart';
import '../../domain/entities/journey_entity.dart';
import '../../domain/repositories/journey_history_repository.dart';

final journeyHistoryRepositoryProvider = Provider<JourneyHistoryRepository>((ref) {
  return JourneyHistoryRepositoryImpl(ref.watch(firestoreProvider));
});

final journeyHistoryStreamProvider = StreamProvider.autoDispose<List<JourneyEntity>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(journeyHistoryRepositoryProvider).watchHistory(uid);
});

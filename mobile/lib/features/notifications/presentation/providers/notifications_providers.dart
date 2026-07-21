import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(firestoreProvider));
});

final notificationsStreamProvider = StreamProvider.autoDispose<List<NotificationEntity>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(notificationsRepositoryProvider).watchNotifications(uid);
});

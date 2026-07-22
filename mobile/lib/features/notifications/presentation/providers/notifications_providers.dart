import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/notification_service.dart';
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

/// Pops a local system notification for every new unread entry in the
/// per-user Firestore `notifications` collection, so they surface like a
/// normal push instead of only being visible if the user opens the
/// in-app Notifications screen. There is no backend in this app to send a
/// real FCM push when one of these documents is created, so this only
/// fires while the app process is alive (same limitation as
/// `GeofenceMonitor` - see features/map/presentation/providers/map_providers.dart).
class NotificationsWatcher {
  NotificationsWatcher({
    required NotificationsRepository repository,
    required NotificationService notificationService,
    required String uid,
  })  : _repository = repository,
        _notificationService = notificationService,
        _uid = uid;

  final NotificationsRepository _repository;
  final NotificationService _notificationService;
  final String _uid;

  final Set<String> _seenIds = {};
  bool _isFirstSnapshot = true;
  StreamSubscription<List<NotificationEntity>>? _subscription;

  void start() {
    _subscription = _repository.watchNotifications(_uid).listen(_onNotifications);
  }

  void _onNotifications(List<NotificationEntity> notifications) {
    if (_isFirstSnapshot) {
      // Don't fire a burst of local notifications for everything that
      // already existed before this session started watching.
      _isFirstSnapshot = false;
      _seenIds.addAll(notifications.map((n) => n.id));
      return;
    }

    for (final notification in notifications) {
      if (notification.isRead || _seenIds.contains(notification.id)) continue;
      _seenIds.add(notification.id);
      _notificationService.showNotification(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.body,
      );
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

final notificationsWatcherProvider = Provider.autoDispose<NotificationsWatcher?>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return null;

  final watcher = NotificationsWatcher(
    repository: ref.watch(notificationsRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
    uid: uid,
  );
  watcher.start();
  ref.onDispose(watcher.dispose);
  return watcher;
});

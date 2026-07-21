import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationEntity>> watchNotifications(String uid);

  Future<Result<void>> markAsRead(String uid, String notificationId);

  Future<Result<void>> markAllAsRead(String uid);
}

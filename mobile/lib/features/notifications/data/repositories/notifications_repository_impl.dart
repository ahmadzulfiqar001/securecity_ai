import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final FirebaseFirestore _firestore;

  NotificationsRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colNotifications);

  @override
  Stream<List<NotificationEntity>> watchNotifications(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => NotificationModel.fromDoc(d).toEntity()).toList());
  }

  @override
  Future<Result<void>> markAsRead(String uid, String notificationId) async {
    try {
      await _collection(uid).doc(notificationId).update({'isRead': true});
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String uid) async {
    try {
      final unread = await _collection(uid).where('isRead', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }
}

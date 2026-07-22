import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/sos_event_entity.dart';
import '../../domain/repositories/sos_repository.dart';
import '../models/sos_event_model.dart';

class SosRepositoryImpl implements SosRepository {
  final FirebaseFirestore _firestore;

  SosRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _sosEvents =>
      _firestore.collection(AppConstants.colSosEvents);

  @override
  Future<Result<String>> createSosEvent(SosEventEntity event) async {
    try {
      final model = SosEventModel(
        userId: event.userId,
        latitude: event.latitude,
        longitude: event.longitude,
        message: event.message,
        status: event.status,
        createdAt: event.createdAt,
      );
      final doc = await _sosEvents.add(model.toJson());
      return Success(doc.id);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> resolveSosEvent(String eventId) async {
    try {
      await _sosEvents.doc(eventId).update({
        'status': 'resolved',
        'resolvedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> attachAudioEvidence(String eventId, String audioUrl) async {
    try {
      await _sosEvents.doc(eventId).update({'audioUrl': audioUrl});
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> updateLocation(String eventId, double latitude, double longitude) async {
    try {
      await _sosEvents.doc(eventId).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }
}

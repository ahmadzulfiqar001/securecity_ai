import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/emergency_contacts_repository.dart';
import '../models/user_model.dart';

class EmergencyContactsRepositoryImpl implements EmergencyContactsRepository {
  final FirebaseFirestore _firestore;

  EmergencyContactsRepositoryImpl(this._firestore);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.colUsers).doc(uid);

  @override
  Stream<List<EmergencyContactEntity>> watchContacts(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return const [];
      final contacts = (data['emergencyContacts'] as List<dynamic>? ?? [])
          .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .map(_toEntity)
          .toList();
      return contacts;
    });
  }

  @override
  Future<Result<void>> addContact(String uid, EmergencyContactEntity contact) async {
    try {
      final current = await _currentContacts(uid);

      if (current.length >= AppConstants.sosMaxEmergencyContacts) {
        return const Error(
          ClientFailure(
            message: 'You can save up to ${AppConstants.sosMaxEmergencyContacts} emergency contacts.',
            code: 'CONTACT_LIMIT_REACHED',
          ),
        );
      }

      current.add(contact);
      await _writeContacts(uid, current);
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> updateContact(String uid, EmergencyContactEntity contact) async {
    try {
      final current = await _currentContacts(uid);
      final index = current.indexWhere((c) => c.id == contact.id);
      if (index == -1) {
        return const Error(NotFoundFailure(message: 'Contact not found.'));
      }
      current[index] = contact;
      await _writeContacts(uid, current);
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> deleteContact(String uid, String contactId) async {
    try {
      final current = await _currentContacts(uid);
      current.removeWhere((c) => c.id == contactId);
      await _writeContacts(uid, current);
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  Future<List<EmergencyContactEntity>> _currentContacts(String uid) async {
    final snapshot = await _userDoc(uid).get();
    final data = snapshot.data();
    if (data == null) return [];
    return (data['emergencyContacts'] as List<dynamic>? ?? [])
        .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
        .map(_toEntity)
        .toList();
  }

  Future<void> _writeContacts(String uid, List<EmergencyContactEntity> contacts) {
    return _userDoc(uid).update({
      'emergencyContacts': contacts.map(_toModel).map((m) => m.toJson()).toList(),
    });
  }

  EmergencyContactEntity _toEntity(EmergencyContactModel model) => EmergencyContactEntity(
        id: model.id,
        name: model.name,
        phone: model.phone,
        relationship: model.relationship,
      );

  EmergencyContactModel _toModel(EmergencyContactEntity entity) => EmergencyContactModel(
        id: entity.id,
        name: entity.name,
        phone: entity.phone,
        relationship: entity.relationship,
      );
}

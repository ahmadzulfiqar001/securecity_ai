import '../../../../core/errors/failures.dart';
import '../../../../core/entities/emergency_contact_entity.dart';

/// Emergency contacts are stored as an embedded list field on the
/// `users/{uid}` document (see the auth feature's `UserModel.emergencyContacts`),
/// not a subcollection - there are at most [AppConstants.sosMaxEmergencyContacts]
/// per user, well within Firestore's single-document size limits.
abstract class EmergencyContactsRepository {
  Stream<List<EmergencyContactEntity>> watchContacts(String uid);

  Future<Result<void>> addContact(String uid, EmergencyContactEntity contact);

  Future<Result<void>> updateContact(String uid, EmergencyContactEntity contact);

  Future<Result<void>> deleteContact(String uid, String contactId);
}

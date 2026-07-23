import '../../../../core/errors/failures.dart';
import '../../../../core/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  Future<Result<UserEntity>> signInWithGoogle();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> sendEmailVerification();

  /// Reloads the current Firebase user and returns their up-to-date
  /// `emailVerified` flag - `reload()` is required because
  /// `authStateChanges()` does not emit when a user verifies their email
  /// out-of-band (e.g. by tapping the link in their inbox).
  Future<Result<bool>> reloadAndCheckEmailVerified();

  Future<Result<void>> signOut();

  Future<Result<UserEntity?>> getCurrentUser();

  /// Updates the signed-in user's `profilePhotoUrl` in Firestore (after the
  /// image itself has already been uploaded to
  /// `users/profile_images/{uid}/...` in Storage) and returns the refreshed
  /// [UserEntity].
  Future<Result<UserEntity>> updateProfilePhoto(String photoUrl);

  /// Updates the signed-in user's self-reported medical fields in
  /// Firestore and returns the refreshed [UserEntity]. Pass `null` for a
  /// field to clear it.
  Future<Result<UserEntity>> updateMedicalInfo({String? bloodGroup, String? medicalNotes});
}

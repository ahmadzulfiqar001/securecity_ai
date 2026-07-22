import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/entities/emergency_contact_entity.dart';
import '../../../../core/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/models/user_model.dart';

/// Auth is handled by Firebase Auth; user profiles live in the Firestore
/// `users` collection (doc id == Firebase UID) - there is no custom backend
/// in the loop. [StorageService] is only used as a local offline-first cache
/// of the profile, not as a source of truth.
class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final StorageService _storageService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthRepositoryImpl({
    required firebase.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required StorageService storageService,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _storageService = storageService;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AppConstants.colUsers);

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Error(AuthFailure(message: 'User authentication failed.'));
      }

      final userModel = await _fetchOrCreateProfile(firebaseUser, fallbackEmail: email);
      await _storageService.saveUser(userModel);
      return Success(_mapToEntity(userModel));
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return const Error(WrongCredentialsFailure());
      } else if (e.code == 'user-not-found') {
        return const Error(UserNotFoundFailure());
      } else if (e.code == 'network-request-failed') {
        return const Error(NetworkFailure());
      }
      return Error(AuthFailure(message: e.message ?? 'Authentication error.', code: e.code));
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Error(AuthFailure(message: 'Registration failed.'));
      }

      await firebaseUser.updateDisplayName(fullName);
      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        // Non-fatal: the Verify Email screen offers a resend button.
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final userModel = UserModel(
        id: firebaseUser.uid,
        firebaseUid: firebaseUser.uid,
        email: email,
        phone: phone,
        fullName: fullName,
        role: 'CITIZEN',
        isActive: true,
        isVerified: false,
        riskScore: 0.0,
        emergencyContacts: const [],
        createdAt: now,
        updatedAt: now,
      );

      await _usersCollection.doc(firebaseUser.uid).set(userModel.toJson());
      await _storageService.saveUser(userModel);
      return Success(_mapToEntity(userModel));
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return const Error(EmailAlreadyInUseFailure());
      } else if (e.code == 'weak-password') {
        return const Error(AuthFailure(message: 'Password is too weak.', code: 'WEAK_PASSWORD'));
      }
      return Error(AuthFailure(message: e.message ?? 'Registration error.', code: e.code));
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Error(AuthFailure(message: 'Google sign-in cancelled.'));
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase.AuthCredential credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Error(AuthFailure(message: 'Google authentication failed.'));
      }

      final userModel = await _fetchOrCreateProfile(firebaseUser, isVerified: true);
      await _storageService.saveUser(userModel);
      return Success(_mapToEntity(userModel));
    } catch (e) {
      return Error(AuthFailure(message: 'Google Sign-in failed.', cause: e));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return const Error(UserNotFoundFailure());
      } else if (e.code == 'invalid-email') {
        return const Error(AuthFailure(message: 'Enter a valid email address.', code: 'INVALID_EMAIL'));
      } else if (e.code == 'network-request-failed') {
        return const Error(NetworkFailure());
      }
      return Error(AuthFailure(message: e.message ?? 'Could not send reset email.', code: e.code));
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Error(AuthFailure(message: 'No signed-in user.'));
      }
      await user.sendEmailVerification();
      return const Success(null);
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return const Error(
          AuthFailure(message: 'Too many requests. Please try again later.', code: 'TOO_MANY_REQUESTS'),
        );
      } else if (e.code == 'network-request-failed') {
        return const Error(NetworkFailure());
      }
      return Error(AuthFailure(message: e.message ?? 'Could not send verification email.', code: e.code));
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<bool>> reloadAndCheckEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return const Success(false);
      await user.reload();
      return Success(_firebaseAuth.currentUser?.emailVerified ?? false);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _storageService.clearUser();
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Success(null);
      }

      final localUser = _storageService.getUser();
      if (localUser != null) {
        return Success(_mapToEntity(localUser));
      }

      final userModel = await _fetchOrCreateProfile(firebaseUser);
      await _storageService.saveUser(userModel);
      return Success(_mapToEntity(userModel));
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  /// Reads the Firestore profile for [firebaseUser], creating it on first
  /// sign-in (e.g. first Google sign-in) if it doesn't exist yet.
  Future<UserModel> _fetchOrCreateProfile(
    firebase.User firebaseUser, {
    String? fallbackEmail,
    bool isVerified = false,
  }) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromJson(snapshot.data()!);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final userModel = UserModel(
      id: firebaseUser.uid,
      firebaseUid: firebaseUser.uid,
      email: firebaseUser.email ?? fallbackEmail ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      fullName: firebaseUser.displayName ?? 'Citizen',
      profilePhotoUrl: firebaseUser.photoURL,
      role: 'CITIZEN',
      isActive: true,
      isVerified: isVerified || firebaseUser.emailVerified,
      riskScore: 0.0,
      emergencyContacts: const [],
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(userModel.toJson());
    return userModel;
  }

  @override
  Future<Result<UserEntity>> updateProfilePhoto(String photoUrl) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Error(AuthFailure(message: 'No signed-in user.'));
      }

      final now = DateTime.now().toUtc().toIso8601String();
      await _usersCollection.doc(firebaseUser.uid).update({
        'profilePhotoUrl': photoUrl,
        'updatedAt': now,
      });

      final snapshot = await _usersCollection.doc(firebaseUser.uid).get();
      final userModel = UserModel.fromJson(snapshot.data()!);
      await _storageService.saveUser(userModel);
      return Success(_mapToEntity(userModel));
    } catch (e) {
      return Error(UnknownFailure(cause: e));
    }
  }

  UserEntity _mapToEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      firebaseUid: model.firebaseUid,
      email: model.email,
      phone: model.phone,
      fullName: model.fullName,
      profilePhotoUrl: model.profilePhotoUrl,
      role: model.role,
      isActive: model.isActive,
      isVerified: model.isVerified,
      riskScore: model.riskScore,
      location: model.location,
      emergencyContacts: model.emergencyContacts
          .map((e) => EmergencyContactEntity(
                id: e.id,
                name: e.name,
                phone: e.phone,
                relationship: e.relationship,
              ))
          .toList(),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}

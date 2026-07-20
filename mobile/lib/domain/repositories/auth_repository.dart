import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

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

  Future<Result<void>> signOut();

  Future<Result<UserEntity?>> getCurrentUser();
}

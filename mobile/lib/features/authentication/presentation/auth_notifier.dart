import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthRepository _authRepository;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _authRepository = authRepository,
        super(const AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    final result = await _authRepository.getCurrentUser();
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, user: user);
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _loginUseCase(email: email, password: password);

    bool success = false;
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, user: user);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _registerUseCase(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    bool success = false;
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, user: user);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepository.signInWithGoogle();

    bool success = false;
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, user: user);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepository.sendPasswordResetEmail(email);

    bool success = false;
    result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<bool> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepository.sendEmailVerification();

    bool success = false;
    result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<bool> checkEmailVerified() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepository.reloadAndCheckEmailVerified();

    bool verified = false;
    result.fold(
      onSuccess: (isVerified) {
        state = state.copyWith(isLoading: false);
        verified = isVerified;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return verified;
  }

  Future<bool> updateProfilePhoto(String photoUrl) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepository.updateProfilePhoto(photoUrl);

    bool success = false;
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, user: user);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<bool> updateMedicalInfo({String? bloodGroup, String? medicalNotes}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepository.updateMedicalInfo(
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
    );

    bool success = false;
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(isLoading: false, user: user);
        success = true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
    return success;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.signOut();
    state = const AuthState();
  }
}

// Auth Repository implementation provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepositoryImpl(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
    storageService: storageService,
  );
});

// Use Cases Providers
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

// Auth State Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final registerUseCase = ref.watch(registerUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  return AuthNotifier(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    authRepository: authRepository,
  );
});

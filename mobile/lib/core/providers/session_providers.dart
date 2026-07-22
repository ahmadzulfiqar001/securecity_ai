import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/auth_notifier.dart';
import '../entities/user_entity.dart';

/// Thin façade over the `authentication` feature's [authNotifierProvider]
/// so every other feature (home, profile, settings, ...) can read the
/// signed-in user and sign out without importing `authentication`
/// directly - only `core/` depends on it, keeping features independent
/// of each other.
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final isSessionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

final sessionErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).errorMessage;
});

final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(authNotifierProvider.notifier).logout();
});

final updateProfilePhotoProvider = Provider<Future<bool> Function(String)>((ref) {
  return (photoUrl) => ref.read(authNotifierProvider.notifier).updateProfilePhoto(photoUrl);
});

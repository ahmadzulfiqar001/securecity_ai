import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../services/storage_service.dart';

/// Persists the user's theme preference (System/Light/Dark) via
/// [StorageService], defaulting to [ThemeMode.dark] to match the app's
/// previous hardcoded behavior.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeModeNotifier(this._storageService) : super(_storageService.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storageService.saveThemeMode(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storageService);
});

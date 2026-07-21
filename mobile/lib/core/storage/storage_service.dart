import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

/// Local offline-first cache — not a source of truth. Auth tokens are
/// managed entirely by the Firebase Auth SDK and are never cached here.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _userKey = 'user_data';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  // User details
  Future<bool> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    return await _prefs.setString(_userKey, userJson);
  }

  UserModel? getUser() {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  Future<bool> clearUser() async {
    return await _prefs.remove(_userKey);
  }

  // Onboarding Status
  Future<bool> saveOnboardingComplete(bool complete) async {
    return await _prefs.setBool(_onboardingCompleteKey, complete);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  // Theme Mode
  Future<bool> saveThemeMode(ThemeMode mode) async {
    return await _prefs.setString(AppConstants.prefKeyThemeMode, mode.name);
  }

  ThemeMode getThemeMode() {
    final value = _prefs.getString(AppConstants.prefKeyThemeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.dark,
    );
  }

  // Shake-to-SOS
  Future<bool> saveShakeDetectionEnabled(bool enabled) async {
    return await _prefs.setBool(AppConstants.prefKeyShakeDetectionEnabled, enabled);
  }

  bool getShakeDetectionEnabled() {
    return _prefs.getBool(AppConstants.prefKeyShakeDetectionEnabled) ?? true;
  }

  // Voice-activated SOS
  Future<bool> saveVoiceActivationEnabled(bool enabled) async {
    return await _prefs.setBool(AppConstants.prefKeyVoiceActivationEnabled, enabled);
  }

  bool getVoiceActivationEnabled() {
    return _prefs.getBool(AppConstants.prefKeyVoiceActivationEnabled) ?? true;
  }

  // Push notifications
  Future<bool> saveNotificationsEnabled(bool enabled) async {
    return await _prefs.setBool(AppConstants.prefKeyNotificationsEnabled, enabled);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool(AppConstants.prefKeyNotificationsEnabled) ?? true;
  }

  // SOS countdown duration
  Future<bool> saveSosCountdownSeconds(int seconds) async {
    return await _prefs.setInt(AppConstants.prefKeySosCountdownSeconds, seconds);
  }

  int getSosCountdownSeconds() {
    return _prefs.getInt(AppConstants.prefKeySosCountdownSeconds) ??
        AppConstants.sosCountdownDefaultSeconds;
  }

  // FCM push token
  Future<bool> saveFcmToken(String token) async {
    return await _prefs.setString(AppConstants.prefKeyFcmToken, token);
  }

  String? getFcmToken() {
    return _prefs.getString(AppConstants.prefKeyFcmToken);
  }

  // General clear
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}

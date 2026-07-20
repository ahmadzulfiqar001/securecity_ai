import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

// SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart first');
});

// Storage Service
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

// Dio and ApiClient providers live in core/network/api_client.dart
// (riverpod codegen: dioProvider, apiClientProvider) — they carry the
// auth/retry/error/logging interceptors and must not be redeclared here.

// Firebase Auth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Firebase Storage
final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// Firebase Messaging
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// Location Service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Current device position — shared by any screen that needs to sort/filter
// by distance (Nearby Services, Area Safety).
final currentPositionProvider = FutureProvider.autoDispose<Position?>((ref) {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});

// Notification Service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final fcm = ref.watch(firebaseMessagingProvider);
  final storage = ref.watch(storageServiceProvider);
  return NotificationService(fcm, storage);
});

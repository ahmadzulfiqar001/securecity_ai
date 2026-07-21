import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm;
  final StorageService _storage;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._fcm, this._storage);

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    // 1. Request permissions for iOS / Android 13+
    await requestPermission();

    // 2. Initialize local notifications for foreground display
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Notification tapped: ${response.payload}');
      },
    );

    // Create Android notification channel for heads up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'securecity_emergency_channel',
      'SecureCity Emergency Alerts',
      description: 'This channel is used for critical smart city safety alerts.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Handle messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received: ${message.messageId}');
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Notification clicked to open app: ${message.data}');
    });

    // 4. Retrieve and persist the FCM Token
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        developer.log('FCM Registration Token: $token');
        await _storage.saveFcmToken(token);
      }
    } catch (e) {
      developer.log('Failed to get FCM token: $e');
    }
  }

  /// Request FCM Push notification permissions
  Future<void> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    developer.log('User notification permission status: ${settings.authorizationStatus}');
  }

  /// Subscribe to a topic (e.g. emergency, traffic, flood)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic');
    } catch (e) {
      developer.log('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic');
    } catch (e) {
      developer.log('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Show a locally-generated alert with no backing FCM message — used by
  /// GeofenceService for zone enter/exit alerts, which are computed
  /// entirely on-device from the location stream.
  Future<void> showGeofenceAlert({required int id, required String title, required String body}) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'securecity_emergency_channel',
          'SecureCity Emergency Alerts',
          channelDescription: 'This channel is used for critical smart city safety alerts.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  /// Show standard local notification when message arrives in foreground
  Future<void> showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'securecity_emergency_channel',
            'SecureCity Emergency Alerts',
            channelDescription: 'This channel is used for critical smart city safety alerts.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

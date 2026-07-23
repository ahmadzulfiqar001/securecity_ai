/// Application-wide constants for SecureCity AI.
abstract final class AppConstants {
  // ─────────────────────────────────────────────────────────────────────────
  // API Configuration
  // ─────────────────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.securecity.ai/v1';
  static const String apiBaseUrlDev = 'https://dev-api.securecity.ai/v1';
  static const String apiBaseUrlStaging = 'https://staging-api.securecity.ai/v1';

  static const Duration apiConnectTimeout = Duration(seconds: 30);
  static const Duration apiReceiveTimeout = Duration(seconds: 60);
  static const Duration apiSendTimeout = Duration(seconds: 30);

  static const int apiMaxRetries = 3;
  static const Duration apiRetryDelay = Duration(seconds: 2);

  // ─────────────────────────────────────────────────────────────────────────
  // Firebase Collections
  // ─────────────────────────────────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colIncidents = 'incidents';
  static const String colNotifications = 'notifications';
  static const String colEmergencyContacts = 'emergency_contacts';
  static const String colJourneyHistory = 'journey_history';
  static const String colSafetyAlerts = 'safety_alerts';
  static const String colAreaSafety = 'area_safety';
  static const String colNearbyServices = 'nearby_services';
  static const String colMapZones = 'map_zones';
  static const String colChatMessages = 'chat_messages';
  static const String colSosEvents = 'sos_events';
  static const String colUserActivity = 'user_activity';
  static const String colWeatherData = 'weather_data';

  // Shared by NotificationEntity.type and SafetyAlertEntity.type - the
  // Notifications feed and the Home screen's broadcast alerts use the same
  // category taxonomy.
  static const List<String> notificationCategoryKeys = [
    'flood',
    'crime',
    'traffic',
    'weather',
    'emergency',
  ];

  // Firebase Storage Buckets / Paths
  static const String storageIncidentMedia = 'incidents/media';
  static const String storageProfileImages = 'users/profile_images';
  static const String storageSosAudio = 'sos/audio';
  static const String storageEvidenceVideos = 'evidence/videos';

  // FCM Topics
  static const String fcmTopicAlerts = 'safety_alerts';
  static const String fcmTopicBroadcast = 'broadcast';
  static const String fcmTopicEmergency = 'emergency';

  // ─────────────────────────────────────────────────────────────────────────
  // SharedPreferences Keys
  // ─────────────────────────────────────────────────────────────────────────
  static const String prefKeyAuthToken = 'auth_token';
  static const String prefKeyRefreshToken = 'refresh_token';
  static const String prefKeyUserId = 'user_id';
  static const String prefKeyUserJson = 'user_json';
  static const String prefKeyOnboardingComplete = 'onboarding_complete';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyLocale = 'locale';
  static const String prefKeyFcmToken = 'fcm_token';
  static const String prefKeyLastKnownLat = 'last_known_lat';
  static const String prefKeyLastKnownLng = 'last_known_lng';
  static const String prefKeyEmergencyContactsJson = 'emergency_contacts_json';
  static const String prefKeyShakeDetectionEnabled = 'shake_detection_enabled';
  static const String prefKeyVoiceActivationEnabled = 'voice_activation_enabled';
  static const String prefKeySosCountdownSeconds = 'sos_countdown_seconds';
  static const String prefKeyNotificationsEnabled = 'notifications_enabled';
  static const String prefKeyNotificationCategories = 'notification_categories';

  // ─────────────────────────────────────────────────────────────────────────
  // Map Configuration
  // ─────────────────────────────────────────────────────────────────────────
  static const double mapDefaultZoom = 14.0;
  static const double mapMinZoom = 5.0;
  static const double mapMaxZoom = 20.0;
  static const double mapCityZoom = 11.0;
  static const double mapNeighborhoodZoom = 15.0;
  static const double mapStreetZoom = 17.0;
  static const double mapBuildingZoom = 19.0;

  /// Default location: Karachi, Pakistan
  static const double mapDefaultLatitude = 24.8607;
  static const double mapDefaultLongitude = 67.0011;

  static const int mapHeatmapRadius = 40;
  static const double mapHeatmapOpacity = 0.7;

  // ─────────────────────────────────────────────────────────────────────────
  // SOS Configuration
  // ─────────────────────────────────────────────────────────────────────────
  static const int sosCountdownDefaultSeconds = 3;
  static const int sosMaxCountdownSeconds = 10;
  static const int sosMaxEmergencyContacts = 5;
  static const double shakeDetectionThreshold = 15.0;
  static const int shakeMinIntervalMs = 500;
  static const String sosDefaultMessage = 'I need help! This is an emergency.';
  static const String sosLocationMessage =
      'My current location: https://maps.google.com/?q={lat},{lng}';

  // ─────────────────────────────────────────────────────────────────────────
  // Media & File Limits
  // ─────────────────────────────────────────────────────────────────────────
  static const int maxImageFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoFileSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const int maxAudioFileSizeBytes = 25 * 1024 * 1024; // 25 MB
  static const int maxIncidentMediaCount = 5;
  static const int imageQuality = 85; // JPEG quality (0-100)
  static const int imageThumbnailSize = 200;
  static const int imageMaxDimension = 1920;

  // ─────────────────────────────────────────────────────────────────────────
  // Pagination
  // ─────────────────────────────────────────────────────────────────────────
  static const int pageSize = 20;
  static const int initialPageSize = 10;
  static const int nearbyServicesRadius = 5000; // meters
  static const int incidentFeedRadius = 10000; // meters

  // ─────────────────────────────────────────────────────────────────────────
  // Location
  // ─────────────────────────────────────────────────────────────────────────
  static const int locationUpdateIntervalMs = 5000; // 5 seconds
  static const double locationDistanceFilter = 10.0; // meters
  static const int locationTimeoutSeconds = 15;
  static const double locationAccuracyThresholdMeters = 50.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Safety Score
  // ─────────────────────────────────────────────────────────────────────────
  static const double safetyScoreMax = 100.0;
  static const double safetyScoreSafeThreshold = 75.0;
  static const double safetyScoreCautionThreshold = 50.0;
  static const double safetyScoreDangerThreshold = 25.0;

  // ─────────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────────
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusCircle = 999.0;

  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double elevationLow = 2.0;
  static const double elevationMedium = 8.0;
  static const double elevationHigh = 16.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  static const double bottomNavHeight = 65.0;
  static const double appBarHeight = 60.0;
  static const double fabSize = 64.0;

  // ─────────────────────────────────────────────────────────────────────────
  // App Meta
  // ─────────────────────────────────────────────────────────────────────────
  static const String appName = 'SecureCity AI';
  static const String appTagline = 'Safety Powered by Intelligence';
  static const String packageId = 'ai.securecity.mobile';
  static const String supportEmail = 'support@securecity.ai';
  static const String privacyPolicyUrl = 'https://securecity.ai/privacy';
  static const String termsOfServiceUrl = 'https://securecity.ai/terms';
}

/// Application-wide constants for the SecureCity AI Authority Dashboard.
/// Collection names match `mobile/lib/core/constants/app_constants.dart`
/// exactly — both apps read/write the same Firestore database.
abstract final class AppConstants {
  static const String appName = 'SecureCity AI';
  static const String appTagline = 'Authority Command Dashboard';

  // ── Firestore Collections ────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colIncidents = 'incidents';
  static const String colSosEvents = 'sos_events';
  static const String colNotifications = 'notifications';
  static const String colAuditLogs = 'audit_logs';
  static const String colCctvCameras = 'cctv_cameras';
  static const String colTrafficData = 'traffic_data';
  static const String colWeatherData = 'weather_data';
  static const String colAreaSafety = 'area_safety';
  static const String colSafetyAlerts = 'safety_alerts';
  static const String colNearbyServices = 'nearby_services';
  static const String colMapZones = 'map_zones';

  // ── Roles (must match the `role` custom claim set by
  // functions/src/index.ts) ─────────────────────────────────────────────
  static const String rolePolice = 'POLICE';
  static const String roleAmbulance = 'AMBULANCE';
  static const String roleFire = 'FIRE';
  static const String roleAdmin = 'ADMIN';
  static const String roleCitizen = 'CITIZEN';

  static const List<String> authorityRoles = [rolePolice, roleAmbulance, roleFire, roleAdmin];

  // ── UI ────────────────────────────────────────────────────────────────
  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 80;
  static const double responsiveBreakpoint = 900;

  // Matches mobile/lib/core/constants/app_constants.dart's spacing/sizing
  // scale exactly, for cross-app visual consistency.
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

  // ── cv_engine (Computer Vision microservice) ────────────────────────────
  // The dashboard's first calls to a Python microservice rather than
  // Firestore — see ComputerVisionScreen. Override via --dart-define for
  // non-local deployments.
  static const String cvEngineHttpBaseUrl = String.fromEnvironment(
    'CV_ENGINE_HTTP_URL',
    defaultValue: 'http://localhost:8002',
  );
  static const String cvEngineWsBaseUrl = String.fromEnvironment(
    'CV_ENGINE_WS_URL',
    defaultValue: 'ws://localhost:8002',
  );

  // ── ai_engine (Crime Heatmap / Safe Route / Safety Score) ───────────────
  static const String aiEngineHttpBaseUrl = String.fromEnvironment(
    'AI_ENGINE_HTTP_URL',
    defaultValue: 'http://localhost:8001',
  );

  static const Duration apiConnectTimeout = Duration(seconds: 15);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);

  // ── GIS / Map ─────────────────────────────────────────────────────────
  static const double mapDefaultLatitude = 24.8607;
  static const double mapDefaultLongitude = 67.0011;
  static const double mapDefaultZoom = 12.0;
  static const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmPackageUserAgent = 'ai.securecity.dashboard';
}

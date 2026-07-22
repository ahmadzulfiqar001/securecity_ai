/// Centralized route path constants for `go_router`.
///
/// Every screen previously referenced raw string literals (`'/login'`,
/// `'/home'`, ...) duplicated across `app_router.dart` and ~29
/// `context.go`/`context.push` call sites - a typo in any one of them would
/// silently fail to navigate. This is the single source of truth instead.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String sos = '/sos';
  static const String map = '/map';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String incidentReport = '/incident/report';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String emergencyContacts = '/emergency-contacts';
  static const String journeyHistory = '/journey-history';
  static const String services = '/services';
  static const String areaSafety = '/area-safety';
}

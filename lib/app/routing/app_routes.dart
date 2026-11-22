abstract final class AppRoutePaths {
  static const dashboard = '/';
  static const authentication = '/authentication';
  static const tracking = '/tracking';
  static const synchronization = '/synchronization';
  static const history = '/history';
  static const map = '/map';
  static const settings = '/settings';

  static String historySession(String sessionId) => '$history/$sessionId';

  static String mapSession(String sessionId) =>
      '$map?sessionId=${Uri.encodeComponent(sessionId)}';
}

abstract final class AppRouteNames {
  static const dashboard = 'dashboard';
  static const authentication = 'authentication';
  static const tracking = 'tracking';
  static const synchronization = 'synchronization';
  static const history = 'history';
  static const map = 'map';
  static const settings = 'settings';
}

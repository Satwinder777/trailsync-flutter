import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger();

  static const _name = 'TrailSync';

  void debug(String message) {
    if (!kDebugMode) return;
    developer.log(message, name: _name);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 1000,
      error: kDebugMode ? error : null,
      stackTrace: kDebugMode ? stackTrace : null,
    );
  }
}

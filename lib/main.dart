import 'dart:async';

import 'app/bootstrap.dart';
import 'core/logging/app_logger.dart';

void main() {
  final logger = AppLogger();

  runZonedGuarded<Future<void>>(
    () => bootstrap(logger: logger),
    (error, stackTrace) => logger.error(
      'Unhandled asynchronous application error',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}

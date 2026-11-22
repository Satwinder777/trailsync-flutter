import 'dart:async';
import 'dart:io';

import 'app_failure.dart';

abstract final class AppErrorMapper {
  static AppFailure from(Object error) {
    if (error is AppFailure) return error;
    if (error is TimeoutException || error is SocketException) {
      return const NetworkFailure();
    }
    if (error is FormatException) return const DataFormatFailure();
    return const UnexpectedFailure();
  }
}

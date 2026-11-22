import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trailsync/core/errors/app_error_mapper.dart';
import 'package:trailsync/core/errors/app_failure.dart';

class _MockUnexpectedException extends Mock implements Exception {}

void main() {
  group('AppErrorMapper', () {
    test('maps timeouts to a network failure', () {
      expect(
        AppErrorMapper.from(TimeoutException('request timed out')),
        isA<NetworkFailure>(),
      );
    });

    test('maps malformed data to a data format failure', () {
      expect(
        AppErrorMapper.from(const FormatException()),
        isA<DataFormatFailure>(),
      );
    });

    test('preserves an existing application failure', () {
      const failure = NetworkFailure('offline');

      expect(AppErrorMapper.from(failure), same(failure));
    });

    test('hides unknown exception details behind a safe failure', () {
      final unknownException = _MockUnexpectedException();

      expect(AppErrorMapper.from(unknownException), isA<UnexpectedFailure>());
      expect(
        AppErrorMapper.from(unknownException).message,
        isNot(contains('coordinates')),
      );
    });
  });
}

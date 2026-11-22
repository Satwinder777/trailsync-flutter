import 'dart:math';

class ExponentialBackoffPolicy {
  ExponentialBackoffPolicy({
    this.baseDelay = const Duration(seconds: 5),
    this.maximumDelay = const Duration(minutes: 30),
    double Function()? randomValue,
  }) : _randomValue = randomValue ?? Random().nextDouble;

  final Duration baseDelay;
  final Duration maximumDelay;
  final double Function() _randomValue;

  Duration delayForAttempt(int attempt) {
    if (attempt < 1) throw ArgumentError.value(attempt, 'attempt');
    final exponent = min(attempt - 1, 30);
    final exponentialMs = baseDelay.inMilliseconds * (1 << exponent);
    final cappedMs = min(exponentialMs, maximumDelay.inMilliseconds);
    final jitteredMs = cappedMs * (0.5 + _randomValue());
    return Duration(
      milliseconds: min(jitteredMs.round(), maximumDelay.inMilliseconds),
    );
  }
}

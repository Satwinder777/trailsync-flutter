import 'dart:math' as math;

import '../entities/position_sample.dart';

/// Rejects malformed, inaccurate, stale and near-duplicate GPS fixes.
class LocationSampleFilter {
  LocationSampleFilter({
    this.minimumDistanceMeters = 5,
    this.maximumAccuracyM = 50,
  });

  final double minimumDistanceMeters;
  final double maximumAccuracyM;
  PositionSample? _lastAccepted;

  void seed(PositionSample? sample) => _lastAccepted = sample;

  bool accepts(PositionSample sample) {
    if (!sample.latitude.isFinite ||
        sample.latitude < -90 ||
        sample.latitude > 90 ||
        !sample.longitude.isFinite ||
        sample.longitude < -180 ||
        sample.longitude > 180 ||
        (sample.altitudeM != null && !sample.altitudeM!.isFinite) ||
        (sample.accuracyM != null &&
            (!sample.accuracyM!.isFinite ||
                sample.accuracyM! < 0 ||
                sample.accuracyM! > maximumAccuracyM)) ||
        (sample.speedMps != null &&
            (!sample.speedMps!.isFinite || sample.speedMps! < 0)) ||
        (sample.headingDeg != null &&
            (!sample.headingDeg!.isFinite ||
                sample.headingDeg! < 0 ||
                sample.headingDeg! >= 360))) {
      return false;
    }

    final previous = _lastAccepted;
    if (previous != null) {
      if (!sample.recordedAt.isAfter(previous.recordedAt)) return false;
      if (_distanceMeters(previous, sample) < minimumDistanceMeters) {
        return false;
      }
    }

    _lastAccepted = sample;
    return true;
  }

  static double distanceMeters(PositionSample first, PositionSample second) =>
      _distanceMeters(first, second);

  static double _distanceMeters(PositionSample first, PositionSample second) {
    const earthRadiusM = 6371000.0;
    final lat1 = _radians(first.latitude);
    final lat2 = _radians(second.latitude);
    final deltaLat = _radians(second.latitude - first.latitude);
    final deltaLon = _radians(second.longitude - first.longitude);
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/position_sample.dart';
import '../../domain/services/location_provider.dart';

class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<PositionSample> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return PositionSample(
      recordedAt: position.timestamp.toUtc(),
      latitude: position.latitude,
      longitude: position.longitude,
      altitudeM: position.altitude,
      accuracyM: position.accuracy,
      speedMps: position.speed,
      headingDeg: position.heading >= 0 && position.heading < 360
          ? position.heading
          : null,
    );
  }

  @override
  Stream<PositionSample> get positionStream =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).map(
        (position) => PositionSample(
          recordedAt: position.timestamp.toUtc(),
          latitude: position.latitude,
          longitude: position.longitude,
          altitudeM: position.altitude,
          accuracyM: position.accuracy,
          speedMps: position.speed,
          headingDeg: position.heading >= 0 && position.heading < 360
              ? position.heading
              : null,
        ),
      );

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

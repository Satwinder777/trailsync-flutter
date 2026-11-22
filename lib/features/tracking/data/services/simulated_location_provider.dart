import '../../domain/entities/position_sample.dart';
import '../../domain/services/location_permission_gateway.dart';
import '../../domain/services/location_provider.dart';

/// Deterministic foreground GPS substitute for local development and tests.
class SimulatedLocationProvider implements LocationProvider {
  SimulatedLocationProvider({
    this.interval = const Duration(seconds: 2),
    this.originLatitude = 37.7749,
    this.originLongitude = -122.4194,
  });

  final Duration interval;
  final double originLatitude;
  final double originLongitude;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<PositionSample> getCurrentPosition() async => PositionSample(
    recordedAt: DateTime.now().toUtc(),
    latitude: originLatitude,
    longitude: originLongitude,
    accuracyM: 4,
  );

  @override
  Stream<PositionSample> get positionStream async* {
    var index = 0;
    while (true) {
      await Future<void>.delayed(interval);
      index++;
      yield PositionSample(
        recordedAt: DateTime.now().toUtc(),
        latitude: originLatitude + (index * 0.0001),
        longitude: originLongitude + (index * 0.0001),
        accuracyM: 4,
        speedMps: 1.4,
        headingDeg: 45,
      );
    }
  }

  @override
  Future<bool> openLocationSettings() async => true;
}

class SimulatedLocationPermissionGateway implements LocationPermissionGateway {
  const SimulatedLocationPermissionGateway({
    this.permissionStatus = LocationPermissionStatus.granted,
  });

  final LocationPermissionStatus permissionStatus;

  @override
  Future<LocationPermissionStatus> requestForegroundPermission() async =>
      permissionStatus;

  @override
  Future<bool> openAppSettings() async => true;
}

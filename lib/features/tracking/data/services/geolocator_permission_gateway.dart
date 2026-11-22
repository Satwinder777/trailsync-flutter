import 'package:geolocator/geolocator.dart';

import '../../domain/services/location_permission_gateway.dart';

class GeolocatorPermissionGateway implements LocationPermissionGateway {
  const GeolocatorPermissionGateway();

  @override
  Future<LocationPermissionStatus> requestForegroundPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.permanentlyDenied,
      _ => LocationPermissionStatus.denied,
    };
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

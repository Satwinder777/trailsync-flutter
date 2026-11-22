enum LocationPermissionStatus { granted, denied, permanentlyDenied }

abstract interface class LocationPermissionGateway {
  Future<LocationPermissionStatus> requestForegroundPermission();

  Future<bool> openAppSettings();
}

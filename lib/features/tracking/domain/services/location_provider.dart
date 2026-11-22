import '../entities/position_sample.dart';

abstract interface class LocationProvider {
  Future<bool> isLocationServiceEnabled();

  Future<PositionSample> getCurrentPosition();

  Stream<PositionSample> get positionStream;

  Future<bool> openLocationSettings();
}

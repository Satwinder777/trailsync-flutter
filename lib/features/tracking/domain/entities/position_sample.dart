import 'package:equatable/equatable.dart';

class PositionSample extends Equatable {
  const PositionSample({
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    this.altitudeM,
    this.accuracyM,
    this.speedMps,
    this.headingDeg,
  });

  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double? altitudeM;
  final double? accuracyM;
  final double? speedMps;
  final double? headingDeg;

  @override
  List<Object?> get props => [
    recordedAt,
    latitude,
    longitude,
    altitudeM,
    accuracyM,
    speedMps,
    headingDeg,
  ];
}

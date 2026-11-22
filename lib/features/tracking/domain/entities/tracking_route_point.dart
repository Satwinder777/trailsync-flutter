import 'package:equatable/equatable.dart';

class TrackingRoutePoint extends Equatable {
  const TrackingRoutePoint({
    required this.recordId,
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
  });

  final String recordId;
  final DateTime recordedAt;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [recordId, recordedAt, latitude, longitude];
}

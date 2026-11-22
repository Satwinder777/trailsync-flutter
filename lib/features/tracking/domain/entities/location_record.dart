import 'package:equatable/equatable.dart';

enum LocationSyncStatus { pending, syncing, retry, synced, failed }

class LocationRecord extends Equatable {
  const LocationRecord({
    required this.clientRecordId,
    required this.sessionId,
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    this.altitudeM,
    this.accuracyM,
    this.speedMps,
    this.headingDeg,
    this.syncStatus = LocationSyncStatus.pending,
  });

  final String clientRecordId;
  final String sessionId;
  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double? altitudeM;
  final double? accuracyM;
  final double? speedMps;
  final double? headingDeg;
  final LocationSyncStatus syncStatus;

  @override
  List<Object?> get props => [
    clientRecordId,
    sessionId,
    recordedAt,
    latitude,
    longitude,
    altitudeM,
    accuracyM,
    speedMps,
    headingDeg,
    syncStatus,
  ];
}

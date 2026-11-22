import 'package:equatable/equatable.dart';

import '../../domain/entities/location_record.dart';
import '../../domain/entities/tracking_session.dart';

enum TrackingStatus {
  idle,
  starting,
  recording,
  stopping,
  completed,
  permissionDenied,
  permissionPermanentlyDenied,
  locationServicesDisabled,
  failure,
}

class TrackingState extends Equatable {
  const TrackingState({
    this.status = TrackingStatus.idle,
    this.session,
    this.lastRecord,
    this.recordCount = 0,
    this.lastLatitude,
    this.lastLongitude,
    this.message,
  });

  final TrackingStatus status;
  final TrackingSession? session;
  final LocationRecord? lastRecord;
  final int recordCount;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? message;

  bool get isRecording => status == TrackingStatus.recording;

  TrackingState copyWith({
    TrackingStatus? status,
    TrackingSession? session,
    LocationRecord? lastRecord,
    int? recordCount,
    double? lastLatitude,
    double? lastLongitude,
    String? message,
    bool clearMessage = false,
    bool clearSession = false,
    bool clearLastRecord = false,
    bool clearLastFix = false,
  }) => TrackingState(
    status: status ?? this.status,
    session: clearSession ? null : session ?? this.session,
    lastRecord: clearLastRecord ? null : lastRecord ?? this.lastRecord,
    recordCount: recordCount ?? this.recordCount,
    lastLatitude: clearLastFix ? null : lastLatitude ?? this.lastLatitude,
    lastLongitude: clearLastFix ? null : lastLongitude ?? this.lastLongitude,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    status,
    session,
    lastRecord,
    recordCount,
    lastLatitude,
    lastLongitude,
    message,
  ];
}

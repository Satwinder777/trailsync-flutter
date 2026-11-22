import 'package:equatable/equatable.dart';

enum TrackingSessionStatus { recording, paused, completed, cancelled }

class TrackingSession extends Equatable {
  const TrackingSession({
    required this.id,
    required this.startedAt,
    required this.status,
    required this.distanceMeters,
    this.ownerUserId,
    this.title,
    this.endedAt,
  });

  final String id;
  final String? ownerUserId;
  final String? title;
  final TrackingSessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceMeters;

  @override
  List<Object?> get props => [
    id,
    ownerUserId,
    title,
    status,
    startedAt,
    endedAt,
    distanceMeters,
  ];
}

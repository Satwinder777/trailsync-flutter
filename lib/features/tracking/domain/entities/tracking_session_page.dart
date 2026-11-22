import 'package:equatable/equatable.dart';

import 'tracking_session.dart';

class TrackingSessionCursor extends Equatable {
  const TrackingSessionCursor({
    required this.startedAt,
    required this.sessionId,
  });

  final DateTime startedAt;
  final String sessionId;

  @override
  List<Object?> get props => [startedAt, sessionId];
}

class TrackingSessionPage extends Equatable {
  const TrackingSessionPage({
    required this.sessions,
    required this.hasMore,
    this.nextCursor,
  });

  final List<TrackingSession> sessions;
  final bool hasMore;
  final TrackingSessionCursor? nextCursor;

  @override
  List<Object?> get props => [sessions, hasMore, nextCursor];
}

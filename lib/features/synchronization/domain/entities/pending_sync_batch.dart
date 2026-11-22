import 'package:equatable/equatable.dart';

import '../../../tracking/domain/entities/location_record.dart';
import '../../../tracking/domain/entities/tracking_session.dart';

class PendingSyncBatch extends Equatable {
  const PendingSyncBatch({
    required this.session,
    required this.records,
    required this.attemptCount,
  });

  final TrackingSession session;
  final List<LocationRecord> records;
  final int attemptCount;

  @override
  List<Object?> get props => [session, records, attemptCount];
}

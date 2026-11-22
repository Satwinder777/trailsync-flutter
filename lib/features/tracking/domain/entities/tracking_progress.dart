import 'package:equatable/equatable.dart';

import 'location_record.dart';
import 'tracking_session.dart';

class TrackingProgress extends Equatable {
  const TrackingProgress({
    required this.session,
    required this.lastRecord,
    required this.recordCount,
  });

  final TrackingSession session;
  final LocationRecord lastRecord;
  final int recordCount;

  @override
  List<Object?> get props => [session, lastRecord, recordCount];
}

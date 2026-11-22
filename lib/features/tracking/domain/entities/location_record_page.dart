import 'package:equatable/equatable.dart';

import 'location_record.dart';

class LocationRecordCursor extends Equatable {
  const LocationRecordCursor({
    required this.recordedAt,
    required this.clientRecordId,
  });

  final DateTime recordedAt;
  final String clientRecordId;

  @override
  List<Object?> get props => [recordedAt, clientRecordId];
}

class LocationRecordPage extends Equatable {
  const LocationRecordPage({
    required this.records,
    required this.hasMore,
    this.nextCursor,
  });

  final List<LocationRecord> records;
  final bool hasMore;
  final LocationRecordCursor? nextCursor;

  @override
  List<Object?> get props => [records, hasMore, nextCursor];
}

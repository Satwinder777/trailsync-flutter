import 'package:equatable/equatable.dart';

import '../../../../features/tracking/domain/entities/location_record.dart';
import '../../../../features/tracking/domain/entities/location_record_page.dart';
import '../../../../features/tracking/domain/entities/tracking_session.dart';
import '../../../../features/tracking/domain/entities/tracking_session_page.dart';
import '../../../../features/tracking/domain/entities/tracking_summary.dart';

enum HistoryListStatus { initial, loading, ready, failure }

enum HistoryDetailStatus { idle, loading, ready, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.listStatus = HistoryListStatus.initial,
    this.detailStatus = HistoryDetailStatus.idle,
    this.sessions = const [],
    this.hasMoreSessions = false,
    this.isLoadingMoreSessions = false,
    this.sessionCursor,
    this.selectedSession,
    this.recordSummary,
    this.records = const [],
    this.hasMoreRecords = false,
    this.isLoadingMoreRecords = false,
    this.recordCursor,
    this.message,
    this.detailMessage,
  });

  final HistoryListStatus listStatus;
  final HistoryDetailStatus detailStatus;
  final List<TrackingSession> sessions;
  final bool hasMoreSessions;
  final bool isLoadingMoreSessions;
  final TrackingSessionCursor? sessionCursor;
  final TrackingSession? selectedSession;
  final SessionRecordSummary? recordSummary;
  final List<LocationRecord> records;
  final bool hasMoreRecords;
  final bool isLoadingMoreRecords;
  final LocationRecordCursor? recordCursor;
  final String? message;
  final String? detailMessage;

  HistoryState copyWith({
    HistoryListStatus? listStatus,
    HistoryDetailStatus? detailStatus,
    List<TrackingSession>? sessions,
    bool? hasMoreSessions,
    bool? isLoadingMoreSessions,
    TrackingSessionCursor? sessionCursor,
    TrackingSession? selectedSession,
    SessionRecordSummary? recordSummary,
    List<LocationRecord>? records,
    bool? hasMoreRecords,
    bool? isLoadingMoreRecords,
    LocationRecordCursor? recordCursor,
    String? message,
    String? detailMessage,
    bool clearSessionCursor = false,
    bool clearDetail = false,
    bool clearRecordCursor = false,
    bool clearMessage = false,
    bool clearDetailMessage = false,
  }) => HistoryState(
    listStatus: listStatus ?? this.listStatus,
    detailStatus: detailStatus ?? this.detailStatus,
    sessions: sessions ?? this.sessions,
    hasMoreSessions: hasMoreSessions ?? this.hasMoreSessions,
    isLoadingMoreSessions: isLoadingMoreSessions ?? this.isLoadingMoreSessions,
    sessionCursor: clearSessionCursor
        ? null
        : sessionCursor ?? this.sessionCursor,
    selectedSession: clearDetail
        ? null
        : selectedSession ?? this.selectedSession,
    recordSummary: clearDetail ? null : recordSummary ?? this.recordSummary,
    records: clearDetail ? const [] : records ?? this.records,
    hasMoreRecords: clearDetail ? false : hasMoreRecords ?? this.hasMoreRecords,
    isLoadingMoreRecords: clearDetail
        ? false
        : isLoadingMoreRecords ?? this.isLoadingMoreRecords,
    recordCursor: clearDetail || clearRecordCursor
        ? null
        : recordCursor ?? this.recordCursor,
    message: clearMessage ? null : message ?? this.message,
    detailMessage: clearDetail || clearDetailMessage
        ? null
        : detailMessage ?? this.detailMessage,
  );

  @override
  List<Object?> get props => [
    listStatus,
    detailStatus,
    sessions,
    hasMoreSessions,
    isLoadingMoreSessions,
    sessionCursor,
    selectedSession,
    recordSummary,
    records,
    hasMoreRecords,
    isLoadingMoreRecords,
    recordCursor,
    message,
    detailMessage,
  ];
}

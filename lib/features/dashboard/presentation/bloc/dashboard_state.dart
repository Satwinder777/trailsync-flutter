import 'package:equatable/equatable.dart';

import '../../../../features/tracking/domain/entities/tracking_summary.dart';

enum DashboardStatus { loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.loading,
    this.summary,
    this.message,
  });

  final DashboardStatus status;
  final TrackingSummary? summary;
  final String? message;

  DashboardState copyWith({
    DashboardStatus? status,
    TrackingSummary? summary,
    String? message,
    bool clearMessage = false,
  }) => DashboardState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [status, summary, message];
}

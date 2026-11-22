import 'package:equatable/equatable.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistorySessionsRequested extends HistoryEvent {
  const HistorySessionsRequested();
}

final class HistoryMoreSessionsRequested extends HistoryEvent {
  const HistoryMoreSessionsRequested();
}

final class HistorySessionDetailsRequested extends HistoryEvent {
  const HistorySessionDetailsRequested(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class HistoryMoreRecordsRequested extends HistoryEvent {
  const HistoryMoreRecordsRequested();
}

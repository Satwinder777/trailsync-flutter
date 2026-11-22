import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../features/tracking/domain/repositories/tracking_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required TrackingRepository trackingRepository})
    : _trackingRepository = trackingRepository,
      super(const HistoryState()) {
    on<HistorySessionsRequested>(_onSessionsRequested);
    on<HistoryMoreSessionsRequested>(_onMoreSessionsRequested);
    on<HistorySessionDetailsRequested>(_onSessionDetailsRequested);
    on<HistoryMoreRecordsRequested>(_onMoreRecordsRequested);
  }

  static const _sessionPageSize = 30;
  static const _recordPageSize = 50;

  final TrackingRepository _trackingRepository;

  Future<void> _onSessionsRequested(
    HistorySessionsRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (state.listStatus == HistoryListStatus.loading) return;
    emit(
      state.copyWith(
        listStatus: HistoryListStatus.loading,
        sessions: const [],
        hasMoreSessions: false,
        isLoadingMoreSessions: false,
        clearSessionCursor: true,
        clearMessage: true,
      ),
    );
    try {
      final page = await _trackingRepository.getSessionsPage(
        limit: _sessionPageSize,
      );
      emit(
        state.copyWith(
          listStatus: HistoryListStatus.ready,
          sessions: page.sessions,
          hasMoreSessions: page.hasMore,
          sessionCursor: page.nextCursor,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          listStatus: HistoryListStatus.failure,
          message: AppErrorMapper.from(error).message,
        ),
      );
    }
  }

  Future<void> _onMoreSessionsRequested(
    HistoryMoreSessionsRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (state.isLoadingMoreSessions ||
        !state.hasMoreSessions ||
        state.sessionCursor == null) {
      return;
    }
    emit(state.copyWith(isLoadingMoreSessions: true));
    try {
      final page = await _trackingRepository.getSessionsPage(
        limit: _sessionPageSize,
        before: state.sessionCursor,
      );
      emit(
        state.copyWith(
          sessions: [...state.sessions, ...page.sessions],
          hasMoreSessions: page.hasMore,
          isLoadingMoreSessions: false,
          sessionCursor: page.nextCursor,
          clearSessionCursor: page.nextCursor == null,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMoreSessions: false,
          message: AppErrorMapper.from(error).message,
        ),
      );
    }
  }

  Future<void> _onSessionDetailsRequested(
    HistorySessionDetailsRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: HistoryDetailStatus.loading,
        clearDetail: true,
      ),
    );
    try {
      final session = await _trackingRepository.getSession(event.sessionId);
      if (session == null) {
        emit(
          state.copyWith(
            detailStatus: HistoryDetailStatus.failure,
            detailMessage: 'This saved session is no longer available.',
          ),
        );
        return;
      }
      final recordSummary = await _trackingRepository.getSessionRecordSummary(
        event.sessionId,
      );
      final page = await _trackingRepository.getRecordsPage(
        sessionId: event.sessionId,
        limit: _recordPageSize,
      );
      emit(
        state.copyWith(
          detailStatus: HistoryDetailStatus.ready,
          selectedSession: session,
          recordSummary: recordSummary,
          records: page.records,
          hasMoreRecords: page.hasMore,
          recordCursor: page.nextCursor,
          clearDetailMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          detailStatus: HistoryDetailStatus.failure,
          detailMessage: AppErrorMapper.from(error).message,
        ),
      );
    }
  }

  Future<void> _onMoreRecordsRequested(
    HistoryMoreRecordsRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final session = state.selectedSession;
    final cursor = state.recordCursor;
    if (session == null ||
        cursor == null ||
        state.isLoadingMoreRecords ||
        !state.hasMoreRecords) {
      return;
    }
    emit(state.copyWith(isLoadingMoreRecords: true));
    try {
      final page = await _trackingRepository.getRecordsPage(
        sessionId: session.id,
        limit: _recordPageSize,
        after: cursor,
      );
      emit(
        state.copyWith(
          records: [...state.records, ...page.records],
          hasMoreRecords: page.hasMore,
          isLoadingMoreRecords: false,
          recordCursor: page.nextCursor,
          clearRecordCursor: page.nextCursor == null,
          clearDetailMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMoreRecords: false,
          detailMessage: AppErrorMapper.from(error).message,
        ),
      );
    }
  }
}

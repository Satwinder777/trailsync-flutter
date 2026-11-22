import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trailsync/features/history/presentation/bloc/history_bloc.dart';
import 'package:trailsync/features/history/presentation/bloc/history_event.dart';
import 'package:trailsync/features/history/presentation/bloc/history_state.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_session.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_session_page.dart';
import 'package:trailsync/features/tracking/domain/repositories/tracking_repository.dart';

void main() {
  late _MockTrackingRepository repository;
  final older = TrackingSession(
    id: '123e4567-e89b-42d3-a456-426614174001',
    status: TrackingSessionStatus.completed,
    startedAt: DateTime.utc(2026, 1, 1),
    endedAt: DateTime.utc(2026, 1, 1, 1),
    distanceMeters: 2400,
  );
  final recent = TrackingSession(
    id: '123e4567-e89b-42d3-a456-426614174002',
    status: TrackingSessionStatus.completed,
    startedAt: DateTime.utc(2026, 1, 2),
    endedAt: DateTime.utc(2026, 1, 2, 1),
    distanceMeters: 5200,
  );

  setUp(() => repository = _MockTrackingRepository());

  blocTest<HistoryBloc, HistoryState>(
    'loads the first cursor page of saved sessions',
    setUp: () => when(() => repository.getSessionsPage(limit: 30)).thenAnswer(
      (_) async => TrackingSessionPage(
        sessions: [recent],
        hasMore: true,
        nextCursor: TrackingSessionCursor(
          startedAt: recent.startedAt,
          sessionId: recent.id,
        ),
      ),
    ),
    build: () => HistoryBloc(trackingRepository: repository),
    act: (bloc) => bloc.add(const HistorySessionsRequested()),
    expect: () => [
      const HistoryState(listStatus: HistoryListStatus.loading),
      HistoryState(
        listStatus: HistoryListStatus.ready,
        sessions: [recent],
        hasMoreSessions: true,
        sessionCursor: TrackingSessionCursor(
          startedAt: recent.startedAt,
          sessionId: recent.id,
        ),
      ),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'appends later session pages without replacing existing sessions',
    setUp: () {
      when(() => repository.getSessionsPage(limit: 30)).thenAnswer(
        (_) async => TrackingSessionPage(
          sessions: [recent],
          hasMore: true,
          nextCursor: TrackingSessionCursor(
            startedAt: recent.startedAt,
            sessionId: recent.id,
          ),
        ),
      );
      when(
        () => repository.getSessionsPage(
          limit: 30,
          before: TrackingSessionCursor(
            startedAt: recent.startedAt,
            sessionId: recent.id,
          ),
        ),
      ).thenAnswer(
        (_) async => TrackingSessionPage(sessions: [older], hasMore: false),
      );
    },
    build: () => HistoryBloc(trackingRepository: repository),
    act: (bloc) async {
      bloc.add(const HistorySessionsRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HistoryMoreSessionsRequested());
    },
    expect: () => [
      const HistoryState(listStatus: HistoryListStatus.loading),
      HistoryState(
        listStatus: HistoryListStatus.ready,
        sessions: [recent],
        hasMoreSessions: true,
        sessionCursor: TrackingSessionCursor(
          startedAt: recent.startedAt,
          sessionId: recent.id,
        ),
      ),
      HistoryState(
        listStatus: HistoryListStatus.ready,
        sessions: [recent],
        hasMoreSessions: true,
        isLoadingMoreSessions: true,
        sessionCursor: TrackingSessionCursor(
          startedAt: recent.startedAt,
          sessionId: recent.id,
        ),
      ),
      HistoryState(
        listStatus: HistoryListStatus.ready,
        sessions: [recent, older],
        hasMoreSessions: false,
      ),
    ],
  );
}

class _MockTrackingRepository extends Mock implements TrackingRepository {}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trailsync/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:trailsync/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_summary.dart';
import 'package:trailsync/features/tracking/domain/repositories/tracking_repository.dart';

void main() {
  late _MockTrackingRepository repository;

  setUp(() => repository = _MockTrackingRepository());

  blocTest<DashboardBloc, DashboardState>(
    'loads aggregate activity through the tracking repository',
    setUp: () {
      when(repository.getTrackingSummary).thenAnswer(
        (_) async =>
            const TrackingSummary(sessionCount: 4, totalDistanceMeters: 12500),
      );
    },
    build: () => DashboardBloc(trackingRepository: repository),
    expect: () => [
      const DashboardState(status: DashboardStatus.loading),
      const DashboardState(
        status: DashboardStatus.ready,
        summary: TrackingSummary(sessionCount: 4, totalDistanceMeters: 12500),
      ),
    ],
    verify: (_) => verify(repository.getTrackingSummary).called(1),
  );

  blocTest<DashboardBloc, DashboardState>(
    'shows a recoverable error when local totals cannot be read',
    setUp: () => when(
      repository.getTrackingSummary,
    ).thenThrow(StateError('database unavailable')),
    build: () => DashboardBloc(trackingRepository: repository),
    expect: () => [
      const DashboardState(status: DashboardStatus.loading),
      isA<DashboardState>()
          .having((state) => state.status, 'status', DashboardStatus.failure)
          .having((state) => state.message, 'message', isNotEmpty),
    ],
  );
}

class _MockTrackingRepository extends Mock implements TrackingRepository {}

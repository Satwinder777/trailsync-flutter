import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trailsync/app/app.dart';
import 'package:trailsync/app/routing/app_router.dart';
import 'package:trailsync/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:trailsync/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:trailsync/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:trailsync/features/history/presentation/bloc/history_bloc.dart';
import 'package:trailsync/features/history/presentation/bloc/history_event.dart';
import 'package:trailsync/features/history/presentation/bloc/history_state.dart';
import 'package:trailsync/features/map/presentation/bloc/map_bloc.dart';
import 'package:trailsync/features/map/presentation/bloc/map_event.dart';
import 'package:trailsync/features/map/presentation/bloc/map_state.dart';
import 'package:trailsync/features/synchronization/presentation/bloc/sync_bloc.dart';
import 'package:trailsync/features/synchronization/presentation/bloc/sync_event.dart';
import 'package:trailsync/features/synchronization/presentation/bloc/sync_state.dart';
import 'package:trailsync/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:trailsync/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:trailsync/features/tracking/presentation/bloc/tracking_state.dart';

void main() {
  testWidgets('dashboard routes to the tracking controls', (tester) async {
    final trackingBloc = _MockTrackingBloc();
    final syncBloc = _MockSyncBloc();
    final dashboardBloc = _MockDashboardBloc();
    final historyBloc = _MockHistoryBloc();
    final mapBloc = _MockMapBloc();
    when(() => trackingBloc.state).thenReturn(const TrackingState());
    when(
      () => syncBloc.state,
    ).thenReturn(const SyncState(status: SyncStatus.idle, hasNetwork: true));
    when(() => dashboardBloc.state).thenReturn(const DashboardState());
    when(() => historyBloc.state).thenReturn(const HistoryState());
    when(() => mapBloc.state).thenReturn(const MapState());
    whenListen(
      trackingBloc,
      const Stream<TrackingState>.empty(),
      initialState: const TrackingState(),
    );
    whenListen(
      syncBloc,
      const Stream<SyncState>.empty(),
      initialState: const SyncState(status: SyncStatus.idle, hasNetwork: true),
    );
    whenListen(
      dashboardBloc,
      const Stream<DashboardState>.empty(),
      initialState: const DashboardState(),
    );
    whenListen(
      historyBloc,
      const Stream<HistoryState>.empty(),
      initialState: const HistoryState(),
    );
    whenListen(
      mapBloc,
      const Stream<MapState>.empty(),
      initialState: const MapState(),
    );
    final router = AppRouter.create(
      trackingBloc: trackingBloc,
      syncBloc: syncBloc,
      dashboardBloc: dashboardBloc,
      historyBloc: historyBloc,
      mapBloc: mapBloc,
      mapTileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    await tester.pumpWidget(TrailSyncApp(router: router));

    expect(find.text('Every trail, in sync.'), findsOneWidget);
    expect(find.text('Start tracking'), findsOneWidget);
    await tester.tap(find.text('Start tracking'));
    verify(() => trackingBloc.add(const TrackingStarted())).called(1);
    router.go('/tracking');
    await tester.pumpAndSettle();

    expect(find.text('Ready to record'), findsOneWidget);
    expect(find.text('Start tracking'), findsOneWidget);

    router.go('/synchronization');
    await tester.pumpAndSettle();
    expect(find.text('Ready to synchronize'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await trackingBloc.close();
    await syncBloc.close();
    await dashboardBloc.close();
    await historyBloc.close();
    await mapBloc.close();
  });
}

class _MockTrackingBloc extends MockBloc<TrackingEvent, TrackingState>
    implements TrackingBloc {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class _MockMapBloc extends MockBloc<MapEvent, MapState> implements MapBloc {}

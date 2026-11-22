import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trailsync/features/map/presentation/bloc/map_bloc.dart';
import 'package:trailsync/features/map/presentation/bloc/map_event.dart';
import 'package:trailsync/features/map/presentation/bloc/map_state.dart';
import 'package:trailsync/features/tracking/domain/entities/position_sample.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_route_point.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_session.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_session_page.dart';
import 'package:trailsync/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:trailsync/features/tracking/domain/services/location_permission_gateway.dart';
import 'package:trailsync/features/tracking/domain/services/location_provider.dart';

void main() {
  late _MockTrackingRepository repository;
  late _FakeLocationProvider locationProvider;
  late _FakePermissionGateway permissionGateway;
  final session = TrackingSession(
    id: '123e4567-e89b-42d3-a456-426614174001',
    status: TrackingSessionStatus.completed,
    startedAt: DateTime.utc(2026, 1, 1),
    endedAt: DateTime.utc(2026, 1, 1, 1),
    distanceMeters: 2450,
  );
  final point = TrackingRoutePoint(
    recordId: '123e4567-e89b-42d3-a456-426614174002',
    recordedAt: DateTime.utc(2026, 1, 1, 0, 0, 10),
    latitude: 37.1,
    longitude: -122.1,
  );

  setUp(() {
    repository = _MockTrackingRepository();
    locationProvider = _FakeLocationProvider();
    permissionGateway = _FakePermissionGateway();
    when(() => repository.getSessionsPage(limit: 100)).thenAnswer(
      (_) async => TrackingSessionPage(sessions: [session], hasMore: false),
    );
    when(repository.getActiveSession).thenAnswer((_) async => null);
    when(
      () => repository.getRouteOverview(sessionId: session.id),
    ).thenAnswer((_) async => [point]);
  });

  blocTest<MapBloc, MapState>(
    'loads a saved route and current position',
    build: () => MapBloc(
      trackingRepository: repository,
      locationProvider: locationProvider,
      permissionGateway: permissionGateway,
    ),
    act: (bloc) => bloc.add(const MapOpened()),
    expect: () => [
      isA<MapState>().having(
        (state) => state.status,
        'status',
        MapLoadStatus.loading,
      ),
      isA<MapState>()
          .having((state) => state.status, 'status', MapLoadStatus.ready)
          .having((state) => state.selectedSession, 'session', session)
          .having((state) => state.routePoints, 'route', [point]),
      isA<MapState>()
          .having(
            (state) => state.locationStatus,
            'location status',
            MapLocationStatus.available,
          )
          .having(
            (state) => state.currentLocation?.latitude,
            'current latitude',
            37.77,
          ),
    ],
  );

  blocTest<MapBloc, MapState>(
    'keeps route history visible when location permission is denied',
    setUp: () {
      permissionGateway.status = LocationPermissionStatus.denied;
    },
    build: () => MapBloc(
      trackingRepository: repository,
      locationProvider: locationProvider,
      permissionGateway: permissionGateway,
    ),
    act: (bloc) => bloc.add(const MapOpened()),
    expect: () => [
      isA<MapState>().having(
        (state) => state.status,
        'status',
        MapLoadStatus.loading,
      ),
      isA<MapState>()
          .having((state) => state.status, 'status', MapLoadStatus.ready)
          .having((state) => state.routePoints, 'route', [point]),
      isA<MapState>()
          .having(
            (state) => state.locationStatus,
            'location status',
            MapLocationStatus.permissionDenied,
          )
          .having((state) => state.currentLocation, 'current location', isNull),
    ],
  );
}

class _MockTrackingRepository extends Mock implements TrackingRepository {}

class _FakeLocationProvider implements LocationProvider {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<PositionSample> getCurrentPosition() async => PositionSample(
    recordedAt: DateTime.utc(2026, 1, 1),
    latitude: 37.77,
    longitude: -122.42,
  );

  @override
  Stream<PositionSample> get positionStream => const Stream.empty();

  @override
  Future<bool> openLocationSettings() async => true;
}

class _FakePermissionGateway implements LocationPermissionGateway {
  LocationPermissionStatus status = LocationPermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<LocationPermissionStatus> requestForegroundPermission() async =>
      status;
}

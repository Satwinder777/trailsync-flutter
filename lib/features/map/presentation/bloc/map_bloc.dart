import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../features/tracking/domain/entities/position_sample.dart';
import '../../../../features/tracking/domain/entities/tracking_route_point.dart';
import '../../../../features/tracking/domain/entities/tracking_session.dart';
import '../../../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../../../features/tracking/domain/services/location_permission_gateway.dart';
import '../../../../features/tracking/domain/services/location_provider.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc({
    required TrackingRepository trackingRepository,
    required LocationProvider locationProvider,
    required LocationPermissionGateway permissionGateway,
  }) : _trackingRepository = trackingRepository,
       _locationProvider = locationProvider,
       _permissionGateway = permissionGateway,
       super(const MapState()) {
    on<MapOpened>(_onOpened);
    on<MapSessionSelected>(_onSessionSelected);
    on<MapTrackingRecordReceived>(_onTrackingRecordReceived);
    on<MapCurrentLocationRefreshRequested>(_onCurrentLocationRefreshRequested);
    on<MapLocationSettingsRequested>(_onLocationSettingsRequested);
    on<MapAppSettingsRequested>(_onAppSettingsRequested);
  }

  static const _sessionMenuLimit = 100;
  static const _maximumLiveRoutePoints = 2000;

  final TrackingRepository _trackingRepository;
  final LocationProvider _locationProvider;
  final LocationPermissionGateway _permissionGateway;

  Future<void> _onOpened(MapOpened event, Emitter<MapState> emit) async {
    emit(
      state.copyWith(
        status: MapLoadStatus.loading,
        isLoadingRoute: true,
        clearMessage: true,
      ),
    );
    try {
      final page = await _trackingRepository.getSessionsPage(
        limit: _sessionMenuLimit,
      );
      TrackingSession? selected;
      if (event.sessionId != null) {
        selected = await _trackingRepository.getSession(event.sessionId!);
      } else {
        selected = await _trackingRepository.getActiveSession();
        if (selected == null && page.sessions.isNotEmpty) {
          selected = page.sessions.first;
        }
      }
      final sessions = [...page.sessions];
      if (selected != null) {
        final selectedId = selected.id;
        if (!sessions.any((session) => session.id == selectedId)) {
          sessions.insert(0, selected);
        }
      }
      final points = selected == null
          ? const <TrackingRoutePoint>[]
          : await _trackingRepository.getRouteOverview(sessionId: selected.id);
      emit(
        state.copyWith(
          status: MapLoadStatus.ready,
          sessions: sessions,
          selectedSession: selected,
          routePoints: points,
          isLoadingRoute: false,
          clearSelectedSession: selected == null,
          clearRoutePoints: selected == null,
          clearMessage: true,
        ),
      );
      await _refreshCurrentLocation(emit);
    } catch (error) {
      emit(
        state.copyWith(
          status: MapLoadStatus.failure,
          isLoadingRoute: false,
          message: AppErrorMapper.from(error).message,
        ),
      );
    }
  }

  Future<void> _onSessionSelected(
    MapSessionSelected event,
    Emitter<MapState> emit,
  ) async {
    final session = await _trackingRepository.getSession(event.sessionId);
    if (session == null) {
      emit(state.copyWith(message: 'This saved route is no longer available.'));
      return;
    }
    emit(
      state.copyWith(
        selectedSession: session,
        clearRoutePoints: true,
        isLoadingRoute: true,
        clearMessage: true,
      ),
    );
    try {
      final points = await _trackingRepository.getRouteOverview(
        sessionId: session.id,
      );
      emit(
        state.copyWith(
          routePoints: points,
          isLoadingRoute: false,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingRoute: false,
          message: AppErrorMapper.from(error).message,
        ),
      );
    }
  }

  void _onTrackingRecordReceived(
    MapTrackingRecordReceived event,
    Emitter<MapState> emit,
  ) {
    var points = state.routePoints;
    if (state.selectedSession?.id == event.record.sessionId &&
        !state.routePoints.any(
          (point) => point.recordId == event.record.clientRecordId,
        )) {
      points = [
        ...state.routePoints,
        TrackingRoutePoint(
          recordId: event.record.clientRecordId,
          recordedAt: event.record.recordedAt,
          latitude: event.record.latitude,
          longitude: event.record.longitude,
        ),
      ];
      if (points.length > _maximumLiveRoutePoints) {
        points = [
          for (var index = 0; index < points.length - 1; index += 2)
            points[index],
          points.last,
        ];
      }
    }
    emit(
      state.copyWith(
        routePoints: points,
        currentLocation: PositionSample(
          recordedAt: event.record.recordedAt,
          latitude: event.record.latitude,
          longitude: event.record.longitude,
          altitudeM: event.record.altitudeM,
          accuracyM: event.record.accuracyM,
          speedMps: event.record.speedMps,
          headingDeg: event.record.headingDeg,
        ),
        locationStatus: MapLocationStatus.available,
        clearLocationMessage: true,
      ),
    );
  }

  Future<void> _onCurrentLocationRefreshRequested(
    MapCurrentLocationRefreshRequested event,
    Emitter<MapState> emit,
  ) => _refreshCurrentLocation(emit);

  Future<void> _refreshCurrentLocation(Emitter<MapState> emit) async {
    emit(
      state.copyWith(
        locationStatus: MapLocationStatus.checking,
        clearLocationMessage: true,
      ),
    );
    try {
      final permission = await _permissionGateway.requestForegroundPermission();
      switch (permission) {
        case LocationPermissionStatus.denied:
          emit(
            state.copyWith(
              locationStatus: MapLocationStatus.permissionDenied,
              locationMessage: 'Allow location access to show your position.',
              clearCurrentLocation: true,
            ),
          );
          return;
        case LocationPermissionStatus.permanentlyDenied:
          emit(
            state.copyWith(
              locationStatus: MapLocationStatus.permissionPermanentlyDenied,
              locationMessage: 'Enable location access in app settings.',
              clearCurrentLocation: true,
            ),
          );
          return;
        case LocationPermissionStatus.granted:
          break;
      }
      if (!await _locationProvider.isLocationServiceEnabled()) {
        emit(
          state.copyWith(
            locationStatus: MapLocationStatus.locationServicesDisabled,
            locationMessage: 'Turn on location services to show your position.',
            clearCurrentLocation: true,
          ),
        );
        return;
      }
      final position = await _locationProvider.getCurrentPosition();
      emit(
        state.copyWith(
          currentLocation: position,
          locationStatus: MapLocationStatus.available,
          clearLocationMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          locationStatus: MapLocationStatus.failure,
          locationMessage: AppErrorMapper.from(error).message,
          clearCurrentLocation: true,
        ),
      );
    }
  }

  Future<void> _onLocationSettingsRequested(
    MapLocationSettingsRequested event,
    Emitter<MapState> emit,
  ) async {
    try {
      await _locationProvider.openLocationSettings();
    } catch (error) {
      emit(state.copyWith(locationMessage: AppErrorMapper.from(error).message));
    }
  }

  Future<void> _onAppSettingsRequested(
    MapAppSettingsRequested event,
    Emitter<MapState> emit,
  ) async {
    try {
      await _permissionGateway.openAppSettings();
    } catch (error) {
      emit(state.copyWith(locationMessage: AppErrorMapper.from(error).message));
    }
  }
}

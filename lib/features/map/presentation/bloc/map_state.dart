import 'package:equatable/equatable.dart';

import '../../../../features/tracking/domain/entities/position_sample.dart';
import '../../../../features/tracking/domain/entities/tracking_route_point.dart';
import '../../../../features/tracking/domain/entities/tracking_session.dart';

enum MapLoadStatus { initial, loading, ready, failure }

enum MapLocationStatus {
  checking,
  available,
  permissionDenied,
  permissionPermanentlyDenied,
  locationServicesDisabled,
  failure,
}

class MapState extends Equatable {
  const MapState({
    this.status = MapLoadStatus.initial,
    this.locationStatus = MapLocationStatus.checking,
    this.sessions = const [],
    this.selectedSession,
    this.routePoints = const [],
    this.currentLocation,
    this.isLoadingRoute = false,
    this.message,
    this.locationMessage,
  });

  final MapLoadStatus status;
  final MapLocationStatus locationStatus;
  final List<TrackingSession> sessions;
  final TrackingSession? selectedSession;
  final List<TrackingRoutePoint> routePoints;
  final PositionSample? currentLocation;
  final bool isLoadingRoute;
  final String? message;
  final String? locationMessage;

  MapState copyWith({
    MapLoadStatus? status,
    MapLocationStatus? locationStatus,
    List<TrackingSession>? sessions,
    TrackingSession? selectedSession,
    List<TrackingRoutePoint>? routePoints,
    PositionSample? currentLocation,
    bool? isLoadingRoute,
    String? message,
    String? locationMessage,
    bool clearSelectedSession = false,
    bool clearRoutePoints = false,
    bool clearCurrentLocation = false,
    bool clearMessage = false,
    bool clearLocationMessage = false,
  }) => MapState(
    status: status ?? this.status,
    locationStatus: locationStatus ?? this.locationStatus,
    sessions: sessions ?? this.sessions,
    selectedSession: clearSelectedSession
        ? null
        : selectedSession ?? this.selectedSession,
    routePoints: clearRoutePoints ? const [] : routePoints ?? this.routePoints,
    currentLocation: clearCurrentLocation
        ? null
        : currentLocation ?? this.currentLocation,
    isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
    message: clearMessage ? null : message ?? this.message,
    locationMessage: clearLocationMessage
        ? null
        : locationMessage ?? this.locationMessage,
  );

  @override
  List<Object?> get props => [
    status,
    locationStatus,
    sessions,
    selectedSession,
    routePoints,
    currentLocation,
    isLoadingRoute,
    message,
    locationMessage,
  ];
}

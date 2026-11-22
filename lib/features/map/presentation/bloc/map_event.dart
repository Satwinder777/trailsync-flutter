import 'package:equatable/equatable.dart';

import '../../../../features/tracking/domain/entities/location_record.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

final class MapOpened extends MapEvent {
  const MapOpened({this.sessionId});

  final String? sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class MapSessionSelected extends MapEvent {
  const MapSessionSelected(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class MapTrackingRecordReceived extends MapEvent {
  const MapTrackingRecordReceived(this.record);

  final LocationRecord record;

  @override
  List<Object?> get props => [record];
}

final class MapCurrentLocationRefreshRequested extends MapEvent {
  const MapCurrentLocationRefreshRequested();
}

final class MapLocationSettingsRequested extends MapEvent {
  const MapLocationSettingsRequested();
}

final class MapAppSettingsRequested extends MapEvent {
  const MapAppSettingsRequested();
}

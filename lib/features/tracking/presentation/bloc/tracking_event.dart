import 'package:equatable/equatable.dart';

import '../../domain/entities/tracking_progress.dart';

sealed class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

final class TrackingStarted extends TrackingEvent {
  const TrackingStarted();
}

final class TrackingStopped extends TrackingEvent {
  const TrackingStopped();
}

final class TrackingOpenPermissionSettingsRequested extends TrackingEvent {
  const TrackingOpenPermissionSettingsRequested();
}

final class TrackingOpenLocationSettingsRequested extends TrackingEvent {
  const TrackingOpenLocationSettingsRequested();
}

final class TrackingProgressReceived extends TrackingEvent {
  const TrackingProgressReceived(this.progress);

  final TrackingProgress progress;

  @override
  List<Object?> get props => [progress];
}

final class TrackingFailed extends TrackingEvent {
  const TrackingFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

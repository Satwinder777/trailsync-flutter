import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

final class SyncInitialized extends SyncEvent {
  const SyncInitialized();
}

final class SyncRequested extends SyncEvent {
  const SyncRequested();
}

final class SyncConnectivityChanged extends SyncEvent {
  const SyncConnectivityChanged(this.hasNetwork);

  final bool hasNetwork;

  @override
  List<Object?> get props => [hasNetwork];
}

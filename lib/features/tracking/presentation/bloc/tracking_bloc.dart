import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../domain/entities/tracking_progress.dart';
import '../../domain/services/tracking_recorder.dart';
import '../../domain/services/tracking_start_result.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc({required TrackingRecorder recorder})
    : _recorder = recorder,
      super(const TrackingState()) {
    on<TrackingStarted>(_onStarted);
    on<TrackingStopped>(_onStopped);
    on<TrackingOpenPermissionSettingsRequested>(_onOpenPermissionSettings);
    on<TrackingOpenLocationSettingsRequested>(_onOpenLocationSettings);
    on<TrackingProgressReceived>(_onProgressReceived);
    on<TrackingFailed>(_onFailed);

    _progressSubscription = _recorder.progressStream.listen(
      (progress) => add(TrackingProgressReceived(progress)),
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(TrackingFailed(error));
      },
    );
  }

  final TrackingRecorder _recorder;
  late final StreamSubscription<TrackingProgress> _progressSubscription;

  Future<void> _onStarted(
    TrackingStarted event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.status == TrackingStatus.starting || state.isRecording) return;
    emit(
      state.copyWith(
        status: TrackingStatus.starting,
        recordCount: 0,
        clearMessage: true,
        clearSession: true,
        clearLastRecord: true,
        clearLastFix: true,
      ),
    );
    try {
      final result = await _recorder.start();
      switch (result) {
        case TrackingStartResult.started:
          emit(state.copyWith(status: TrackingStatus.recording));
        case TrackingStartResult.permissionDenied:
          emit(
            state.copyWith(
              status: TrackingStatus.permissionDenied,
              message: 'Location permission is needed to record a trail.',
            ),
          );
        case TrackingStartResult.permissionPermanentlyDenied:
          emit(
            state.copyWith(
              status: TrackingStatus.permissionPermanentlyDenied,
              message: 'Enable location access for TrailSync in app settings.',
            ),
          );
        case TrackingStartResult.locationServicesDisabled:
          emit(
            state.copyWith(
              status: TrackingStatus.locationServicesDisabled,
              message: 'Turn on location services to record a trail.',
            ),
          );
      }
    } catch (error) {
      final failure = AppErrorMapper.from(error);
      emit(
        state.copyWith(
          status: TrackingStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> _onStopped(
    TrackingStopped event,
    Emitter<TrackingState> emit,
  ) async {
    if (!state.isRecording) return;
    emit(state.copyWith(status: TrackingStatus.stopping));
    try {
      await _recorder.stop();
      emit(state.copyWith(status: TrackingStatus.completed));
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackingStatus.failure,
          message: AppErrorMapper.from(error).message,
        ),
      );
    }
  }

  Future<void> _onOpenPermissionSettings(
    TrackingOpenPermissionSettingsRequested event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      await _recorder.openAppSettings();
    } catch (error) {
      emit(state.copyWith(message: AppErrorMapper.from(error).message));
    }
  }

  Future<void> _onOpenLocationSettings(
    TrackingOpenLocationSettingsRequested event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      await _recorder.openLocationSettings();
    } catch (error) {
      emit(state.copyWith(message: AppErrorMapper.from(error).message));
    }
  }

  void _onProgressReceived(
    TrackingProgressReceived event,
    Emitter<TrackingState> emit,
  ) {
    final progress = event.progress;
    emit(
      state.copyWith(
        status: TrackingStatus.recording,
        session: progress.session,
        lastRecord: progress.lastRecord,
        recordCount: progress.recordCount,
        lastLatitude: progress.lastRecord.latitude,
        lastLongitude: progress.lastRecord.longitude,
      ),
    );
  }

  Future<void> _onFailed(
    TrackingFailed event,
    Emitter<TrackingState> emit,
  ) async {
    try {
      await _recorder.stop();
    } catch (_) {
      // Keep the original capture failure visible to the user.
    }
    emit(
      state.copyWith(
        status: TrackingStatus.failure,
        message: AppErrorMapper.from(event.error).message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _progressSubscription.cancel();
    await _recorder.dispose();
    await super.close();
  }
}

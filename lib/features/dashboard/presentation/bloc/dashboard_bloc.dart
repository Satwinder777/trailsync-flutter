import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../tracking/domain/repositories/tracking_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required TrackingRepository trackingRepository})
    : _trackingRepository = trackingRepository,
      super(const DashboardState()) {
    on<DashboardRefreshRequested>(_onRefreshRequested);
    add(const DashboardRefreshRequested());
  }

  final TrackingRepository _trackingRepository;

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading, clearMessage: true));
    try {
      final summary = await _trackingRepository.getTrackingSummary();
      emit(state.copyWith(status: DashboardStatus.ready, summary: summary));
    } catch (error) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          message: AppErrorMapper.from(error).message,
        ),
      );
    }
  }
}

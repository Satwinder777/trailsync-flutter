import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_page_scaffold.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Tracking',
      body: BlocBuilder<TrackingBloc, TrackingState>(
        builder: (context, state) {
          final bloc = context.read<TrackingBloc>();
          final needsSettings =
              state.status == TrackingStatus.permissionPermanentlyDenied;
          final locationDisabled =
              state.status == TrackingStatus.locationServicesDisabled;
          final isBusy =
              state.status == TrackingStatus.starting ||
              state.status == TrackingStatus.stopping;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          _TrackingStatusIcon(isRecording: state.isRecording),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusText(state.status),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  state.isRecording
                                      ? 'Your location is being saved to this device.'
                                      : 'Ready when you are. GPS points are stored locally.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.message != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Text(state.message!),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: isBusy || state.isRecording
                                  ? null
                                  : () => bloc.add(const TrackingStarted()),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start tracking'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: state.isRecording
                                  ? () => bloc.add(const TrackingStopped())
                                  : null,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (needsSettings || locationDisabled)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: TextButton.icon(
                          onPressed: () => bloc.add(
                            needsSettings
                                ? const TrackingOpenPermissionSettingsRequested()
                                : const TrackingOpenLocationSettingsRequested(),
                          ),
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(
                            needsSettings
                                ? 'Open app settings'
                                : 'Open location settings',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Live session',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (state.isRecording)
                          const _RecordingBadge()
                        else
                          const Icon(
                            Icons.route_outlined,
                            color: AppColors.forest,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _SessionMetric(
                            label: 'Distance',
                            value:
                                '${((state.session?.distanceMeters ?? 0) / 1000).toStringAsFixed(2)} km',
                            icon: Icons.straighten,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SessionMetric(
                            label: 'GPS points',
                            value: state.recordCount.toString(),
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (state.lastLatitude != null &&
                        state.lastLongitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          'Latest fix  ·  ${state.lastLatitude!.toStringAsFixed(5)}, '
                          '${state.lastLongitude!.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    const _LocalFirstNote(
                      text:
                          'Every accepted point is saved locally first. '
                          'Cloud sync runs separately when available.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusText(TrackingStatus status) => switch (status) {
    TrackingStatus.idle => 'Ready to record',
    TrackingStatus.starting => 'Checking location access…',
    TrackingStatus.recording => 'Recording trail',
    TrackingStatus.stopping => 'Saving trail…',
    TrackingStatus.completed => 'Trail saved locally',
    TrackingStatus.permissionDenied => 'Location permission denied',
    TrackingStatus.permissionPermanentlyDenied =>
      'Location permission required',
    TrackingStatus.locationServicesDisabled => 'Location services are off',
    TrackingStatus.failure => 'Recording needs attention',
  };
}

class _TrackingStatusIcon extends StatelessWidget {
  const _TrackingStatusIcon({required this.isRecording});

  final bool isRecording;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: isRecording ? AppColors.accent : AppColors.canvas,
      borderRadius: BorderRadius.circular(18),
    ),
    child: SizedBox(
      width: 56,
      height: 56,
      child: Icon(
        isRecording ? Icons.radio_button_checked : Icons.gps_fixed,
        color: AppColors.forest,
        size: 27,
      ),
    ),
  );
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(30),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fiber_manual_record, size: 10, color: AppColors.forest),
        SizedBox(width: AppSpacing.xs),
        Text('LIVE', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _SessionMetric extends StatelessWidget {
  const _SessionMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.forest, size: 19),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _LocalFirstNote extends StatelessWidget {
  const _LocalFirstNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.verified_user_outlined,
        size: 17,
        color: AppColors.forest,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

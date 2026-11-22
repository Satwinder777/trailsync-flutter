import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          final status = _statusText(state.status);
          final needsSettings =
              state.status == TrackingStatus.permissionPermanentlyDenied;
          final locationDisabled =
              state.status == TrackingStatus.locationServicesDisabled;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status, style: Theme.of(context).textTheme.titleLarge),
                    if (state.message != null) ...[
                      const SizedBox(height: 8),
                      Text(state.message!),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                state.status == TrackingStatus.starting ||
                                    state.isRecording ||
                                    state.status == TrackingStatus.stopping
                                ? null
                                : () => bloc.add(const TrackingStarted()),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start tracking'),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    if (needsSettings || locationDisabled) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
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
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local capture',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text('Saved points: ${state.recordCount}'),
                    if (state.session != null)
                      Text(
                        'Distance: '
                        '${(state.session!.distanceMeters / 1000).toStringAsFixed(2)} km',
                      ),
                    if (state.lastLatitude != null &&
                        state.lastLongitude != null)
                      Text(
                        'Last fix: ${state.lastLatitude!.toStringAsFixed(5)}, '
                        '${state.lastLongitude!.toStringAsFixed(5)}',
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accepted GPS points are saved on this device. '
                      'Cloud synchronization runs separately and retries '
                      'when the backend is available.',
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

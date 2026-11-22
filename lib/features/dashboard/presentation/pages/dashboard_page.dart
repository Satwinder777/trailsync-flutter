import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_metric_card.dart';
import '../../../../core/design_system/widgets/app_page_scaffold.dart';
import '../../../synchronization/presentation/bloc/sync_bloc.dart';
import '../../../synchronization/presentation/bloc/sync_state.dart';
import '../../../tracking/presentation/bloc/tracking_bloc.dart';
import '../../../tracking/presentation/bloc/tracking_event.dart';
import '../../../tracking/presentation/bloc/tracking_state.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<TrackingBloc, TrackingState>(
    listenWhen: (previous, current) =>
        previous.status != current.status &&
        (current.status == TrackingStatus.recording ||
            current.status == TrackingStatus.completed),
    listener: (context, _) =>
        context.read<DashboardBloc>().add(const DashboardRefreshRequested()),
    child: AppPageScaffold(
      title: 'TrailSync',
      actions: [
        IconButton(
          tooltip: 'Synchronization',
          onPressed: () => context.push(AppRoutePaths.synchronization),
          icon: const Icon(Icons.sync),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1080
              ? 4
              : constraints.maxWidth >= 600
              ? 3
              : 2;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              const _WelcomeCard(),
              const SizedBox(height: AppSpacing.md),
              const _TrackingControlsCard(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 178,
                children: const [
                  _SessionCountCard(),
                  _DistanceCard(),
                  _PendingCountCard(),
                  _SyncedCountCard(),
                  _ConnectivityCard(),
                  _LastSyncCard(),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Explore', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ExploreButton(
                    label: 'History',
                    icon: Icons.history,
                    onPressed: () => context.push(AppRoutePaths.history),
                  ),
                  _ExploreButton(
                    label: 'Map',
                    icon: Icons.map_outlined,
                    onPressed: () => context.push(AppRoutePaths.map),
                  ),
                  _ExploreButton(
                    label: 'Synchronization',
                    icon: Icons.sync,
                    onPressed: () =>
                        context.push(AppRoutePaths.synchronization),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<DashboardBloc, DashboardState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.message != current.message,
                builder: (context, state) {
                  if (state.status == DashboardStatus.failure) {
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.message ?? 'Activity totals unavailable.'),
                          TextButton.icon(
                            onPressed: () => context.read<DashboardBloc>().add(
                              const DashboardRefreshRequested(),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.route_outlined,
              color: AppColors.forest,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Every trail, in sync.'),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Record offline and keep your routes ready wherever you go.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TrackingControlsCard extends StatelessWidget {
  const _TrackingControlsCard();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrackingBloc, TrackingState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.message != current.message,
        builder: (context, state) {
          final bloc = context.read<TrackingBloc>();
          final isBusy =
              state.status == TrackingStatus.starting ||
              state.status == TrackingStatus.stopping;
          final locationDisabled =
              state.status == TrackingStatus.locationServicesDisabled;
          final permissionPermanent =
              state.status == TrackingStatus.permissionPermanentlyDenied;
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isRecording
                          ? Icons.radio_button_checked
                          : Icons.gps_fixed,
                      color: state.isRecording ? AppColors.forest : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _trackingStatusLabel(state.status),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (state.isRecording) const _ElapsedDistanceHint(),
                  ],
                ),
                if (state.message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(state.message!),
                ],
                if (locationDisabled || permissionPermanent)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => bloc.add(
                        permissionPermanent
                            ? const TrackingOpenPermissionSettingsRequested()
                            : const TrackingOpenLocationSettingsRequested(),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        permissionPermanent
                            ? 'Open app settings'
                            : 'Open location settings',
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: isBusy || state.isRecording
                          ? null
                          : () => bloc.add(const TrackingStarted()),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start tracking'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isRecording
                          ? () => bloc.add(const TrackingStopped())
                          : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  String _trackingStatusLabel(TrackingStatus status) => switch (status) {
    TrackingStatus.idle => 'Ready for your next trail',
    TrackingStatus.starting => 'Getting location ready…',
    TrackingStatus.recording => 'Trail recording',
    TrackingStatus.stopping => 'Saving your trail…',
    TrackingStatus.completed => 'Trail saved on this device',
    TrackingStatus.permissionDenied => 'Location permission is needed',
    TrackingStatus.permissionPermanentlyDenied => 'Location access is off',
    TrackingStatus.locationServicesDisabled => 'Location services are off',
    TrackingStatus.failure => 'Tracking needs attention',
  };
}

class _ElapsedDistanceHint extends StatelessWidget {
  const _ElapsedDistanceHint();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<TrackingBloc, TrackingState, double>(
        selector: (state) => state.session?.distanceMeters ?? 0,
        builder: (context, distance) => Text(
          '${(distance / 1000).toStringAsFixed(2)} km',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );
}

class _SessionCountCard extends StatelessWidget {
  const _SessionCountCard();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<DashboardBloc, DashboardState, String>(
        selector: (state) => state.summary?.sessionCount.toString() ?? '—',
        builder: (context, value) => AppMetricCard(
          label: 'Total sessions',
          value: value,
          icon: Icons.route_outlined,
        ),
      );
}

class _DistanceCard extends StatelessWidget {
  const _DistanceCard();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardBloc, DashboardState>(
        buildWhen: (previous, current) => previous.summary != current.summary,
        builder: (context, dashboardState) =>
            BlocSelector<
              TrackingBloc,
              TrackingState,
              ({double distance, bool recording})
            >(
              selector: (state) => (
                distance: state.session?.distanceMeters ?? 0,
                recording: state.isRecording,
              ),
              builder: (context, live) {
                final completedDistance =
                    dashboardState.summary?.totalDistanceMeters ?? 0;
                final distance =
                    completedDistance + (live.recording ? live.distance : 0);
                return AppMetricCard(
                  label: 'Total distance',
                  value: '${(distance / 1000).toStringAsFixed(2)} km',
                  icon: Icons.straighten,
                  detail: live.recording ? 'Includes this live trail' : null,
                );
              },
            ),
      );
}

class _PendingCountCard extends StatelessWidget {
  const _PendingCountCard();

  @override
  Widget build(BuildContext context) => BlocSelector<SyncBloc, SyncState, int>(
    selector: (state) => state.pendingCount,
    builder: (context, count) => AppMetricCard(
      label: 'Pending records',
      value: count.toString(),
      icon: Icons.cloud_upload_outlined,
    ),
  );
}

class _SyncedCountCard extends StatelessWidget {
  const _SyncedCountCard();

  @override
  Widget build(BuildContext context) => BlocSelector<SyncBloc, SyncState, int>(
    selector: (state) => state.syncedCount,
    builder: (context, count) => AppMetricCard(
      label: 'Synced records',
      value: count.toString(),
      icon: Icons.cloud_done_outlined,
    ),
  );
}

class _ConnectivityCard extends StatelessWidget {
  const _ConnectivityCard();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SyncBloc, SyncState, ({bool? connected, SyncStatus status})>(
        selector: (state) =>
            (connected: state.hasNetwork, status: state.status),
        builder: (context, connection) => AppMetricCard(
          label: 'Connectivity',
          value: connection.connected == true
              ? 'Network available'
              : connection.connected == false
              ? 'Offline'
              : 'Checking…',
          detail: _syncStatusLabel(connection.status),
          icon: connection.connected == true
              ? Icons.wifi
              : Icons.wifi_off_outlined,
        ),
      );
}

class _LastSyncCard extends StatelessWidget {
  const _LastSyncCard();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SyncBloc, SyncState, DateTime?>(
        selector: (state) => state.lastSyncAt,
        builder: (context, lastSync) => AppMetricCard(
          label: 'Last synchronized',
          value: lastSync == null ? 'Not yet' : _formatDateTime(lastSync),
          icon: Icons.history_toggle_off,
        ),
      );
}

class _ExploreButton extends StatelessWidget {
  const _ExploreButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
  );
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}

String _syncStatusLabel(SyncStatus status) => switch (status) {
  SyncStatus.checking => 'Checking backend…',
  SyncStatus.offline => 'No network connection',
  SyncStatus.idle => 'Ready to sync',
  SyncStatus.syncing => 'Syncing saved points…',
  SyncStatus.completed => 'Sync complete',
  SyncStatus.retryScheduled => 'Retry scheduled',
  SyncStatus.backendUnavailable => 'Backend unavailable',
  SyncStatus.notConfigured => 'Backend not configured',
  SyncStatus.authenticationRequired => 'Sign in to sync',
  SyncStatus.failure => 'Sync needs attention',
};

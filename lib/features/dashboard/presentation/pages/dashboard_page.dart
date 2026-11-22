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
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              const _WelcomeCard(),
              const SizedBox(height: AppSpacing.lg),
              const _TrackingControlsCard(),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeading(
                title: 'Your trail overview',
                subtitle: 'A quick look at your saved activity',
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
              _SectionHeading(
                title: 'Explore TrailSync',
                subtitle: 'Review routes and manage your saved data',
              ),
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
    padding: EdgeInsets.zero,
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, AppColors.forestDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -28,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 22,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.explore_outlined,
                      size: 17,
                      color: AppColors.lime,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'OFFLINE-FIRST GPS JOURNAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Every trail, in sync.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    'Record your route without a signal. Your data stays on '
                    'this device until it is safely synchronized.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _WorkflowPill(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _WorkflowPill extends StatelessWidget {
  const _WorkflowPill();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed, size: 16, color: AppColors.lime),
          SizedBox(width: AppSpacing.xs),
          Text('Capture', style: TextStyle(color: Colors.white, fontSize: 12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.arrow_forward, size: 13, color: AppColors.lime),
          ),
          Text(
            'Save locally',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.arrow_forward, size: 13, color: AppColors.lime),
          ),
          Text('Sync', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.xs),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    ],
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: state.isRecording
                            ? AppColors.accent
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          state.isRecording
                              ? Icons.radio_button_checked
                              : Icons.gps_fixed,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _trackingStatusLabel(state.status),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (state.isRecording)
                      const _LiveDistanceBadge()
                    else
                      const _ReadyBadge(),
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
                const SizedBox(height: AppSpacing.md),
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

class _LiveDistanceBadge extends StatelessWidget {
  const _LiveDistanceBadge();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<TrackingBloc, TrackingState, double>(
        selector: (state) => state.session?.distanceMeters ?? 0,
        builder: (context, distance) => Text(
          '${(distance / 1000).toStringAsFixed(2)} km',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.forest),
        ),
      );
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      'READY',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.mutedInk,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w700,
      ),
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

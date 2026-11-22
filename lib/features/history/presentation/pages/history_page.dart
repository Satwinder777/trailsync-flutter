import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_empty_state.dart';
import '../../../../core/design_system/widgets/app_page_scaffold.dart';
import '../../../tracking/domain/entities/tracking_session.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistorySessionsRequested());
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Trail history',
    body: BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (previous, current) =>
          previous.listStatus != current.listStatus ||
          previous.sessions != current.sessions ||
          previous.hasMoreSessions != current.hasMoreSessions ||
          previous.isLoadingMoreSessions != current.isLoadingMoreSessions ||
          previous.message != current.message,
      builder: (context, state) {
        if (state.listStatus == HistoryListStatus.initial ||
            state.listStatus == HistoryListStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.listStatus == HistoryListStatus.failure &&
            state.sessions.isEmpty) {
          return _HistoryError(
            message: state.message ?? 'Saved sessions could not be loaded.',
            onRetry: () => context.read<HistoryBloc>().add(
              const HistorySessionsRequested(),
            ),
          );
        }
        if (state.sessions.isEmpty) {
          return const AppEmptyState(
            icon: Icons.route_outlined,
            title: 'No trails yet',
            message: 'Start tracking and your saved sessions will appear here.',
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 280 &&
                state.hasMoreSessions &&
                !state.isLoadingMoreSessions) {
              context.read<HistoryBloc>().add(
                const HistoryMoreSessionsRequested(),
              );
            }
            return false;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount:
                state.sessions.length +
                1 +
                (state.hasMoreSessions || state.isLoadingMoreSessions ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _HistoryIntro();
              }
              final sessionIndex = index - 1;
              if (sessionIndex == state.sessions.length) {
                return Center(
                  child: state.isLoadingMoreSessions
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        )
                      : TextButton.icon(
                          onPressed: () => context.read<HistoryBloc>().add(
                            const HistoryMoreSessionsRequested(),
                          ),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Load older trails'),
                        ),
                );
              }
              final session = state.sessions[sessionIndex];
              return _SessionCard(
                session: session,
                onTap: () =>
                    context.push('${AppRoutePaths.history}/${session.id}'),
              );
            },
          ),
        );
      },
    ),
  );
}

class _HistoryIntro extends StatelessWidget {
  const _HistoryIntro();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.route_outlined, color: AppColors.forest),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your trail archive',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Routes are stored on this device and ready to review.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final TrackingSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final endedAt = session.endedAt ?? DateTime.now().toUtc();
    final duration = endedAt.difference(session.startedAt);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title?.trim().isNotEmpty == true
                      ? session.title!
                      : _sessionName(session.startedAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _SessionStatusChip(status: session.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_formatDate(session.startedAt)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _CompactMetric(
                icon: Icons.straighten,
                value: _formatDistance(session.distanceMeters),
              ),
              _CompactMetric(
                icon: Icons.timer_outlined,
                value: _formatDuration(duration),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionStatusChip extends StatelessWidget {
  const _SessionStatusChip({required this.status});

  final TrackingSessionStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(_sessionIcon(status), size: 16),
    label: Text(_sessionStatusLabel(status)),
    visualDensity: VisualDensity.compact,
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: AppSpacing.xs),
      Text(value),
    ],
  );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

String _sessionName(DateTime startedAt) => 'Trail · ${_formatDate(startedAt)}';

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}  '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatDistance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(2)} km'
    : '${meters.toStringAsFixed(0)} m';

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
}

String _sessionStatusLabel(TrackingSessionStatus status) => switch (status) {
  TrackingSessionStatus.recording => 'Recording',
  TrackingSessionStatus.paused => 'Paused',
  TrackingSessionStatus.completed => 'Completed',
  TrackingSessionStatus.cancelled => 'Cancelled',
};

IconData _sessionIcon(TrackingSessionStatus status) => switch (status) {
  TrackingSessionStatus.recording => Icons.radio_button_checked,
  TrackingSessionStatus.paused => Icons.pause_circle_outline,
  TrackingSessionStatus.completed => Icons.check_circle_outline,
  TrackingSessionStatus.cancelled => Icons.cancel_outlined,
};

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/widgets/app_empty_state.dart';
import '../../core/design_system/widgets/app_page_scaffold.dart';
import '../../features/authentication/presentation/pages/authentication_page.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/history/presentation/pages/history_session_details_page.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/synchronization/presentation/bloc/sync_bloc.dart';
import '../../features/synchronization/presentation/pages/synchronization_page.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../../features/tracking/presentation/pages/tracking_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static GoRouter create({
    required TrackingBloc trackingBloc,
    required SyncBloc syncBloc,
    required DashboardBloc dashboardBloc,
    required HistoryBloc historyBloc,
    required MapBloc mapBloc,
    required String mapTileUrlTemplate,
  }) {
    return GoRouter(
      initialLocation: AppRoutePaths.dashboard,
      routes: [
        GoRoute(
          name: AppRouteNames.dashboard,
          path: AppRoutePaths.dashboard,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: trackingBloc),
              BlocProvider.value(value: syncBloc),
              BlocProvider.value(value: dashboardBloc),
            ],
            child: const DashboardPage(),
          ),
        ),
        GoRoute(
          name: AppRouteNames.authentication,
          path: AppRoutePaths.authentication,
          builder: (_, _) => const AuthenticationPage(),
        ),
        GoRoute(
          name: AppRouteNames.tracking,
          path: AppRoutePaths.tracking,
          builder: (_, _) => BlocProvider.value(
            value: trackingBloc,
            child: const TrackingPage(),
          ),
        ),
        GoRoute(
          name: AppRouteNames.synchronization,
          path: AppRoutePaths.synchronization,
          builder: (_, _) => BlocProvider.value(
            value: syncBloc,
            child: const SynchronizationPage(),
          ),
        ),
        GoRoute(
          name: AppRouteNames.history,
          path: AppRoutePaths.history,
          builder: (_, _) => BlocProvider.value(
            value: historyBloc,
            child: const HistoryPage(),
          ),
          routes: [
            GoRoute(
              name: 'history-session',
              path: ':sessionId',
              builder: (_, state) => BlocProvider.value(
                value: historyBloc,
                child: HistorySessionDetailsPage(
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          name: AppRouteNames.map,
          path: AppRoutePaths.map,
          builder: (_, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: trackingBloc),
              BlocProvider.value(value: mapBloc),
              BlocProvider.value(value: syncBloc),
            ],
            child: MapPage(
              tileUrlTemplate: mapTileUrlTemplate,
              sessionId: state.uri.queryParameters['sessionId'],
            ),
          ),
        ),
        GoRoute(
          name: AppRouteNames.settings,
          path: AppRoutePaths.settings,
          builder: (_, _) => const SettingsPage(),
        ),
      ],
      errorBuilder: (context, state) => const AppPageScaffold(
        title: 'Page unavailable',
        body: AppEmptyState(
          icon: Icons.route_outlined,
          title: 'This page is unavailable',
          message: 'Return to the dashboard and choose a TrailSync module.',
        ),
      ),
    );
  }
}

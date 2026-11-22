import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';
import '../../features/synchronization/data/local/drift_sync_local_store.dart';
import '../../features/synchronization/data/remote/supabase_sync_remote_data_source.dart';
import '../../features/synchronization/data/repositories/offline_first_synchronization_repository.dart';
import '../../features/synchronization/data/services/connectivity_plus_monitor.dart';
import '../../features/synchronization/domain/repositories/sync_local_store.dart';
import '../../features/synchronization/domain/repositories/sync_remote_data_source.dart';
import '../../features/synchronization/domain/repositories/synchronization_repository.dart';
import '../../features/synchronization/domain/services/sync_connectivity_monitor.dart';
import '../../features/synchronization/presentation/bloc/sync_bloc.dart';
import '../../features/tracking/data/local/tracking_local_data_source.dart';
import '../../features/tracking/data/repositories/local_tracking_repository.dart';
import '../../features/tracking/data/services/geolocator_location_provider.dart';
import '../../features/tracking/data/services/geolocator_permission_gateway.dart';
import '../../features/tracking/data/services/simulated_location_provider.dart';
import '../../features/tracking/data/services/uuid_record_id_generator.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/domain/services/location_permission_gateway.dart';
import '../../features/tracking/domain/services/location_provider.dart';
import '../../features/tracking/domain/services/record_id_generator.dart';
import '../../features/tracking/domain/services/tracking_recorder.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../config/environment_config.dart';
import '../database/app_database.dart';
import '../routing/app_router.dart';

void configureDependencies({
  required EnvironmentConfig environment,
  required AppLogger logger,
  required SupabaseClient? supabaseClient,
}) {
  final container = GetIt.instance;
  container.registerSingleton<EnvironmentConfig>(environment);
  container.registerSingleton<AppLogger>(logger);
  container.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    ),
    dispose: (dio) => dio.close(force: true),
  );
  container.registerLazySingleton<AppDatabase>(
    AppDatabase.new,
    dispose: (database) => database.close(),
  );
  container.registerLazySingleton<TrackingLocalDataSource>(
    () => TrackingLocalDataSource(container<AppDatabase>()),
  );
  container.registerLazySingleton<TrackingRepository>(
    () => LocalTrackingRepository(
      dataSource: container<TrackingLocalDataSource>(),
    ),
  );
  container.registerLazySingleton<SyncLocalStore>(
    () => DriftSyncLocalStore(container<AppDatabase>()),
  );
  container.registerLazySingleton<SyncRemoteDataSource>(
    () => SupabaseSyncRemoteDataSource(
      environment: environment,
      dio: container<Dio>(),
      client: supabaseClient,
    ),
  );
  container.registerLazySingleton<SyncConnectivityMonitor>(
    ConnectivityPlusMonitor.new,
  );
  container.registerLazySingleton<SynchronizationRepository>(
    () => OfflineFirstSynchronizationRepository(
      localStore: container<SyncLocalStore>(),
      remoteDataSource: container<SyncRemoteDataSource>(),
      batchSize: environment.syncBatchSize,
    ),
  );

  if (environment.useSimulatedLocation) {
    container.registerLazySingleton<LocationProvider>(
      SimulatedLocationProvider.new,
    );
    container.registerLazySingleton<LocationPermissionGateway>(
      SimulatedLocationPermissionGateway.new,
    );
  } else {
    container.registerLazySingleton<LocationProvider>(
      GeolocatorLocationProvider.new,
    );
    container.registerLazySingleton<LocationPermissionGateway>(
      GeolocatorPermissionGateway.new,
    );
  }

  container.registerLazySingleton<RecordIdGenerator>(UuidRecordIdGenerator.new);
  container.registerLazySingleton<TrackingRecorder>(
    () => TrackingRecorder(
      repository: container<TrackingRepository>(),
      locationProvider: container<LocationProvider>(),
      permissionGateway: container<LocationPermissionGateway>(),
      recordIdGenerator: container<RecordIdGenerator>(),
    ),
  );
  container.registerLazySingleton<TrackingBloc>(
    () => TrackingBloc(recorder: container<TrackingRecorder>()),
    dispose: (bloc) => bloc.close(),
  );
  container.registerLazySingleton<SyncBloc>(
    () => SyncBloc(
      repository: container<SynchronizationRepository>(),
      connectivityMonitor: container<SyncConnectivityMonitor>(),
    ),
    dispose: (bloc) => bloc.close(),
  );
  container.registerLazySingleton<DashboardBloc>(
    () => DashboardBloc(trackingRepository: container<TrackingRepository>()),
    dispose: (bloc) => bloc.close(),
  );
  container.registerLazySingleton<HistoryBloc>(
    () => HistoryBloc(trackingRepository: container<TrackingRepository>()),
    dispose: (bloc) => bloc.close(),
  );
  container.registerLazySingleton<MapBloc>(
    () => MapBloc(
      trackingRepository: container<TrackingRepository>(),
      locationProvider: container<LocationProvider>(),
      permissionGateway: container<LocationPermissionGateway>(),
    ),
    dispose: (bloc) => bloc.close(),
  );
  container.registerLazySingleton<GoRouter>(
    () => AppRouter.create(
      trackingBloc: container<TrackingBloc>(),
      syncBloc: container<SyncBloc>(),
      dashboardBloc: container<DashboardBloc>(),
      historyBloc: container<HistoryBloc>(),
      mapBloc: container<MapBloc>(),
      mapTileUrlTemplate: environment.mapTileUrlTemplate,
    ),
    dispose: (router) => router.dispose(),
  );
}

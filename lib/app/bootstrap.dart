import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/logging/app_bloc_observer.dart';
import '../core/logging/app_logger.dart';
import 'app.dart';
import 'config/environment_config.dart';
import 'di/injection.dart';

Future<void> bootstrap({required AppLogger logger}) async {
  WidgetsFlutterBinding.ensureInitialized();
  _installFrameworkErrorHandlers(logger);

  await dotenv.load(fileName: '.env');
  final environment = EnvironmentConfig.fromMap(dotenv.env);

  SupabaseClient? supabaseClient;
  if (environment.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: environment.supabaseUrl,
        publishableKey: environment.supabasePublishableKey,
      );
      supabaseClient = Supabase.instance.client;
    } catch (error, stackTrace) {
      logger.error(
        'Supabase client initialization failed; offline mode remains available.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Bloc.observer = AppBlocObserver(logger);
  configureDependencies(
    environment: environment,
    logger: logger,
    supabaseClient: supabaseClient,
  );

  runApp(TrailSyncApp(router: GetIt.instance<GoRouter>()));
}

void _installFrameworkErrorHandlers(AppLogger logger) {
  FlutterError.onError = (details) {
    if (details.stack != null) {
      logger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    } else {
      logger.error('Flutter framework error', error: details.exception);
    }
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error(
      'Unhandled platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}

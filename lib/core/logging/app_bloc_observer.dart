import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

class AppBlocObserver extends BlocObserver {
  AppBlocObserver(this._logger);

  final AppLogger _logger;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      'BLoC error in ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/services/sync_connectivity_monitor.dart';

class ConnectivityPlusMonitor implements SyncConnectivityMonitor {
  ConnectivityPlusMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasNetworkConnection() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get connectionChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}

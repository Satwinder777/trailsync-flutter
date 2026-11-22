abstract interface class SyncConnectivityMonitor {
  Future<bool> hasNetworkConnection();

  Stream<bool> get connectionChanges;
}

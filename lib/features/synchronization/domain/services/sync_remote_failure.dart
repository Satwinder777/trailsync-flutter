enum SyncRemoteFailureKind {
  configuration,
  authentication,
  timeout,
  rateLimited,
  network,
  unavailable,
  server,
}

class SyncRemoteFailure implements Exception {
  const SyncRemoteFailure(this.kind, this.message);

  final SyncRemoteFailureKind kind;
  final String message;

  @override
  String toString() => message;
}

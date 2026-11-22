import 'dart:async';

import '../entities/location_record.dart';
import '../entities/position_sample.dart';
import '../entities/tracking_progress.dart';
import '../repositories/tracking_repository.dart';
import 'location_permission_gateway.dart';
import 'location_provider.dart';
import 'location_sample_filter.dart';
import 'record_id_generator.dart';
import 'tracking_start_result.dart';

/// Coordinates capture and local commits. Every progress event represents a
/// record which has already been written to SQLite.
class TrackingRecorder {
  TrackingRecorder({
    required TrackingRepository repository,
    required LocationProvider locationProvider,
    required LocationPermissionGateway permissionGateway,
    required RecordIdGenerator recordIdGenerator,
    LocationSampleFilter? sampleFilter,
  }) : _repository = repository,
       _locationProvider = locationProvider,
       _permissionGateway = permissionGateway,
       _recordIdGenerator = recordIdGenerator,
       _sampleFilter = sampleFilter ?? LocationSampleFilter();

  final TrackingRepository _repository;
  final LocationProvider _locationProvider;
  final LocationPermissionGateway _permissionGateway;
  final RecordIdGenerator _recordIdGenerator;
  final LocationSampleFilter _sampleFilter;
  final StreamController<TrackingProgress> _progressController =
      StreamController<TrackingProgress>.broadcast();

  StreamSubscription<PositionSample>? _positionSubscription;
  Future<void> _pendingWrites = Future<void>.value();
  String? _sessionId;
  int _recordCount = 0;
  bool _isStarting = false;

  Stream<TrackingProgress> get progressStream => _progressController.stream;

  bool get isRecording => _positionSubscription != null;

  Future<TrackingStartResult> start() async {
    if (isRecording || _isStarting) return TrackingStartResult.started;
    _isStarting = true;
    try {
      final permission = await _permissionGateway.requestForegroundPermission();
      if (permission == LocationPermissionStatus.denied) {
        return TrackingStartResult.permissionDenied;
      }
      if (permission == LocationPermissionStatus.permanentlyDenied) {
        return TrackingStartResult.permissionPermanentlyDenied;
      }
      if (!await _locationProvider.isLocationServiceEnabled()) {
        return TrackingStartResult.locationServicesDisabled;
      }

      final existingSession = await _repository.getActiveSession();
      final session =
          existingSession ??
          await _repository.createSession(startedAt: DateTime.now().toUtc());
      _sessionId = session.id;
      final latest = await _repository.getLatestRecord(session.id);
      _sampleFilter.seed(latest == null ? null : _sampleFromRecord(latest));
      _recordCount = await _repository.countRecords(session.id);

      _positionSubscription = _locationProvider.positionStream.listen(
        _enqueueSample,
        onError: (Object error, StackTrace stackTrace) {
          if (!_progressController.isClosed) {
            _progressController.addError(error, stackTrace);
          }
        },
      );
      return TrackingStartResult.started;
    } finally {
      _isStarting = false;
    }
  }

  void _enqueueSample(PositionSample sample) {
    _pendingWrites = _pendingWrites.then((_) => _persistIfAccepted(sample));
    _pendingWrites = _pendingWrites.catchError((
      Object error,
      StackTrace stack,
    ) {
      if (!_progressController.isClosed) {
        _progressController.addError(error, stack);
      }
    });
  }

  Future<void> _persistIfAccepted(PositionSample sample) async {
    final sessionId = _sessionId;
    if (sessionId == null || !_sampleFilter.accepts(sample)) return;

    final record = LocationRecord(
      clientRecordId: _recordIdGenerator.create(),
      sessionId: sessionId,
      recordedAt: sample.recordedAt.toUtc(),
      latitude: sample.latitude,
      longitude: sample.longitude,
      altitudeM: sample.altitudeM,
      accuracyM: sample.accuracyM,
      speedMps: sample.speedMps,
      headingDeg: sample.headingDeg,
    );
    final savedSession = await _repository.appendRecord(record);
    _recordCount++;
    if (!_progressController.isClosed) {
      _progressController.add(
        TrackingProgress(
          session: savedSession,
          lastRecord: record,
          recordCount: _recordCount,
        ),
      );
    }
  }

  Future<void> stop() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
    await _pendingWrites;

    final sessionId = _sessionId;
    _sessionId = null;
    if (sessionId != null) {
      await _repository.completeSession(
        sessionId: sessionId,
        endedAt: DateTime.now().toUtc(),
      );
    }
  }

  Future<bool> openAppSettings() => _permissionGateway.openAppSettings();

  Future<bool> openLocationSettings() =>
      _locationProvider.openLocationSettings();

  Future<void> dispose() async {
    await stop();
    await _progressController.close();
  }

  PositionSample _sampleFromRecord(LocationRecord record) => PositionSample(
    recordedAt: record.recordedAt,
    latitude: record.latitude,
    longitude: record.longitude,
    altitudeM: record.altitudeM,
    accuracyM: record.accuracyM,
    speedMps: record.speedMps,
    headingDeg: record.headingDeg,
  );
}

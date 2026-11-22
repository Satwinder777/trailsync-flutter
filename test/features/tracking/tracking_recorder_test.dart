import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/app/database/app_database.dart';
import 'package:trailsync/features/tracking/data/local/tracking_local_data_source.dart';
import 'package:trailsync/features/tracking/data/repositories/local_tracking_repository.dart';
import 'package:trailsync/features/tracking/domain/entities/position_sample.dart';
import 'package:trailsync/features/tracking/domain/services/location_permission_gateway.dart';
import 'package:trailsync/features/tracking/domain/services/location_provider.dart';
import 'package:trailsync/features/tracking/domain/services/record_id_generator.dart';
import 'package:trailsync/features/tracking/domain/services/tracking_recorder.dart';
import 'package:trailsync/features/tracking/domain/services/tracking_start_result.dart';
import 'package:trailsync/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:trailsync/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:trailsync/features/tracking/presentation/bloc/tracking_state.dart';

void main() {
  late AppDatabase database;
  late LocalTrackingRepository repository;
  late ControlledLocationProvider provider;
  late TestPermissionGateway permission;
  late TrackingRecorder recorder;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalTrackingRepository(
      dataSource: TrackingLocalDataSource(database),
    );
    provider = ControlledLocationProvider();
    permission = TestPermissionGateway();
    recorder = TrackingRecorder(
      repository: repository,
      locationProvider: provider,
      permissionGateway: permission,
      recordIdGenerator: IncrementingRecordIdGenerator(),
    );
  });

  tearDown(() async {
    await recorder.dispose();
    if (provider.listenCount > 0) await provider.close();
    await database.close();
  });

  test(
    'persists accepted fixes before publishing progress and cancels GPS',
    () async {
      final emitted = Completer<void>();
      final progressSubscription = recorder.progressStream.listen((
        progress,
      ) async {
        final stored = await repository.getLatestRecord(progress.session.id);
        expect(stored, progress.lastRecord);
        if (!emitted.isCompleted) emitted.complete();
      });

      expect(await recorder.start(), TrackingStartResult.started);
      provider.add(_sample(0, longitude: -122.0));
      await emitted.future.timeout(const Duration(seconds: 2));
      await recorder.stop();

      expect(provider.cancelCount, 1);
      final active = await repository.getActiveSession();
      expect(active, isNull);
      await progressSubscription.cancel();
    },
  );

  test('does not create a session when permission is denied', () async {
    permission.status = LocationPermissionStatus.denied;

    expect(await recorder.start(), TrackingStartResult.permissionDenied);
    expect(await repository.getActiveSession(), isNull);
    expect(provider.listenCount, 0);
  });

  test('does not create a session when GPS services are disabled', () async {
    provider.enabled = false;

    expect(
      await recorder.start(),
      TrackingStartResult.locationServicesDisabled,
    );
    expect(await repository.getActiveSession(), isNull);
    expect(provider.listenCount, 0);
  });

  test('TrackingBloc exposes permission denial as immutable state', () async {
    permission.status = LocationPermissionStatus.permanentlyDenied;
    final bloc = TrackingBloc(recorder: recorder);
    final deniedState = bloc.stream.firstWhere(
      (state) => state.status == TrackingStatus.permissionPermanentlyDenied,
    );

    bloc.add(const TrackingStarted());

    final state = await deniedState.timeout(const Duration(seconds: 2));
    expect(state.message, contains('app settings'));
    expect(state.recordCount, 0);
    await bloc.close();
  });

  test(
    'sample filter ignores inaccurate and duplicate movement fixes',
    () async {
      final accepted = <String>[];
      final progressSubscription = recorder.progressStream.listen(
        (progress) => accepted.add(progress.lastRecord.clientRecordId),
      );
      await recorder.start();
      provider.add(_sample(0, longitude: -122.0, accuracy: 80));
      provider.add(_sample(1, longitude: -122.0));
      provider.add(_sample(2, longitude: -122.0));
      provider.add(_sample(3, longitude: -121.9999));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(accepted, [
        '00000000-0000-4000-8000-000000000001',
        '00000000-0000-4000-8000-000000000002',
      ]);
      await progressSubscription.cancel();
    },
  );
}

PositionSample _sample(
  int seconds, {
  required double longitude,
  double accuracy = 4,
}) => PositionSample(
  recordedAt: DateTime.utc(2026, 1, 1, 0, 0, seconds),
  latitude: 37,
  longitude: longitude,
  accuracyM: accuracy,
);

class ControlledLocationProvider implements LocationProvider {
  ControlledLocationProvider() {
    _controller = StreamController<PositionSample>(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  late final StreamController<PositionSample> _controller;
  bool enabled = true;
  int listenCount = 0;
  int cancelCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<PositionSample> getCurrentPosition() async =>
      _sample(0, longitude: -122.0);

  @override
  Stream<PositionSample> get positionStream => _controller.stream;

  void add(PositionSample sample) => _controller.add(sample);

  @override
  Future<bool> openLocationSettings() async => true;

  Future<void> close() => _controller.close();
}

class TestPermissionGateway implements LocationPermissionGateway {
  LocationPermissionStatus status = LocationPermissionStatus.granted;

  @override
  Future<LocationPermissionStatus> requestForegroundPermission() async =>
      status;

  @override
  Future<bool> openAppSettings() async => true;
}

class IncrementingRecordIdGenerator implements RecordIdGenerator {
  int _next = 0;

  @override
  String create() =>
      '00000000-0000-4000-8000-${(++_next).toString().padLeft(12, '0')}';
}

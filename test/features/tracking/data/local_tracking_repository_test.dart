import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/app/database/app_database.dart' as storage;
import 'package:trailsync/features/tracking/data/local/tracking_local_data_source.dart';
import 'package:trailsync/features/tracking/data/repositories/local_tracking_repository.dart';
import 'package:trailsync/features/tracking/domain/entities/location_record.dart';

void main() {
  late storage.AppDatabase database;
  late LocalTrackingRepository repository;

  setUp(() {
    database = storage.AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalTrackingRepository(
      dataSource: TrackingLocalDataSource(database),
    );
  });

  tearDown(() async => database.close());

  test('persists session and location points and pages newest first', () async {
    final start = DateTime.utc(2026, 1, 1);
    final session = await repository.createSession(startedAt: start);
    final first = _record(
      id: '123e4567-e89b-42d3-a456-426614174000',
      sessionId: session.id,
      time: start,
      latitude: 37.0,
      longitude: -122.0,
    );
    final second = _record(
      id: '123e4567-e89b-42d3-a456-426614174001',
      sessionId: session.id,
      time: start.add(const Duration(seconds: 10)),
      latitude: 37.001,
      longitude: -122.0,
    );

    final afterFirst = await repository.appendRecord(first);
    final afterSecond = await repository.appendRecord(second);
    final latest = await repository.getLatestRecord(session.id);
    final page = await repository.getRecordsPage(
      sessionId: session.id,
      limit: 1,
    );
    final nextPage = await repository.getRecordsPage(
      sessionId: session.id,
      limit: 1,
      after: page.nextCursor,
    );

    expect(afterFirst.distanceMeters, 0);
    expect(afterSecond.distanceMeters, greaterThan(100));
    expect(latest, second);
    expect(page.records, [second]);
    expect(page.hasMore, isTrue);
    expect(nextPage.records, [first]);
    expect(nextPage.hasMore, isFalse);
  });

  test('rejects invalid coordinates at the database boundary', () async {
    final session = await repository.createSession(
      startedAt: DateTime.utc(2026),
    );

    await expectLater(
      repository.appendRecord(
        _record(
          id: '123e4567-e89b-42d3-a456-426614174002',
          sessionId: session.id,
          time: DateTime.utc(2026),
          latitude: 91,
          longitude: 0,
        ),
      ),
      throwsA(anything),
    );

    expect(await repository.getLatestRecord(session.id), isNull);
  });

  test('cascades session deletion to local location rows', () async {
    final session = await repository.createSession(
      startedAt: DateTime.utc(2026),
    );
    await repository.appendRecord(
      _record(
        id: '123e4567-e89b-42d3-a456-426614174003',
        sessionId: session.id,
        time: DateTime.utc(2026),
        latitude: 37,
        longitude: -122,
      ),
    );
    await (database.delete(
      database.trackingSessions,
    )..where((row) => row.id.equals(session.id))).go();

    expect(await repository.getLatestRecord(session.id), isNull);
  });

  test('bounds page size', () async {
    await expectLater(
      repository.getRecordsPage(sessionId: 'unused', limit: 201),
      throwsArgumentError,
    );
  });

  test(
    'pages sessions and computes dashboard and session sync totals',
    () async {
      final first = await repository.createSession(
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final second = await repository.createSession(
        startedAt: DateTime.utc(2026, 1, 2),
      );
      final page = await repository.getSessionsPage(limit: 1);
      final nextPage = await repository.getSessionsPage(
        limit: 1,
        before: page.nextCursor,
      );

      expect(page.sessions, [second]);
      expect(page.hasMore, isTrue);
      expect(nextPage.sessions, [first]);
      expect(nextPage.hasMore, isFalse);

      await repository.appendRecord(
        _record(
          id: '123e4567-e89b-42d3-a456-426614174010',
          sessionId: second.id,
          time: DateTime.utc(2026, 1, 2),
          latitude: 37,
          longitude: -122,
        ),
      );
      await repository.appendRecord(
        _record(
          id: '123e4567-e89b-42d3-a456-426614174011',
          sessionId: second.id,
          time: DateTime.utc(2026, 1, 2, 0, 0, 10),
          latitude: 37.001,
          longitude: -122,
        ),
      );
      final activeSummary = await repository.getTrackingSummary();
      expect(activeSummary.sessionCount, 2);
      expect(activeSummary.totalDistanceMeters, 0);

      final recordSummary = await repository.getSessionRecordSummary(second.id);
      expect(recordSummary.recordCount, 2);
      expect(recordSummary.pendingCount, 2);
      expect(recordSummary.syncedCount, 0);

      await repository.completeSession(
        sessionId: second.id,
        endedAt: DateTime.utc(2026, 1, 2, 0, 1),
      );
      final completedSummary = await repository.getTrackingSummary();
      expect(completedSummary.sessionCount, 2);
      expect(completedSummary.totalDistanceMeters, greaterThan(100));
    },
  );

  test('bounds route overview while preserving route endpoints', () async {
    final session = await repository.createSession(
      startedAt: DateTime.utc(2026, 2, 1),
    );
    for (var index = 0; index < 20; index++) {
      await repository.appendRecord(
        _record(
          id: _recordId(index),
          sessionId: session.id,
          time: DateTime.utc(2026, 2, 1).add(Duration(seconds: index)),
          latitude: 37 + (index * 0.0001),
          longitude: -122,
        ),
      );
    }

    final route = await repository.getRouteOverview(
      sessionId: session.id,
      maxPoints: 4,
    );

    expect(route, isNotEmpty);
    expect(route.length, lessThanOrEqualTo(4));
    expect(route.first.latitude, 37);
    expect(route.last.latitude, closeTo(37.0019, 0.000001));
  });

  test('rejects unreasonable route point limits', () async {
    await expectLater(
      repository.getRouteOverview(sessionId: 'unused', maxPoints: 1),
      throwsArgumentError,
    );
  });
}

LocationRecord _record({
  required String id,
  required String sessionId,
  required DateTime time,
  required double latitude,
  required double longitude,
}) => LocationRecord(
  clientRecordId: id,
  sessionId: sessionId,
  recordedAt: time,
  latitude: latitude,
  longitude: longitude,
  accuracyM: 4,
);

String _recordId(int index) =>
    '123e4567-e89b-42d3-a456-${(426614174100 + index).toString()}';

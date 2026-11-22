import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import '../../features/tracking/data/local/tables/location_records.dart';
import '../../features/tracking/data/local/tables/tracking_sessions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [TrackingSessions, LocationRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : this.withExecutor(_openConnection());

  AppDatabase.withExecutor(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 1) {
        await migrator.createAll();
      }
      if (from >= 1 && from < 2) {
        await migrator.addColumn(locationRecords, locationRecords.syncStatus);
        await migrator.addColumn(locationRecords, locationRecords.syncAttempts);
        await migrator.addColumn(
          locationRecords,
          locationRecords.nextAttemptAt,
        );
        await migrator.addColumn(
          locationRecords,
          locationRecords.lastSyncError,
        );
        await migrator.addColumn(locationRecords, locationRecords.syncedAt);
        await customStatement(
          'CREATE INDEX location_records_sync_due_idx '
          'ON location_records '
          '(sync_status, next_attempt_at, session_id, recorded_at)',
        );
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(
        "UPDATE location_records SET sync_status = 'pending' "
        "WHERE sync_status = 'syncing'",
      );
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final temporaryDirectory = await getTemporaryDirectory();
    final temporaryPath = temporaryDirectory.path;

    final databaseFile = File(
      p.join(supportDirectory.path, 'trailsync.sqlite'),
    );
    return NativeDatabase.createInBackground(
      databaseFile,
      isolateSetup: () {
        sqlite3.tempDirectory = temporaryPath;
      },
      setup: (database) {
        database.execute('PRAGMA journal_mode = WAL');
        database.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}

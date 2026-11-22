import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/app/database/app_database.dart' as storage;
import 'package:trailsync/features/synchronization/data/local/drift_sync_local_store.dart';

void main() {
  test(
    'migrates a version 1 local database and queues existing points',
    () async {
      final executor = NativeDatabase.memory(
        setup: (database) {
          database.execute('''
          CREATE TABLE tracking_sessions (
            id TEXT NOT NULL PRIMARY KEY,
            owner_user_id TEXT,
            title TEXT,
            status TEXT NOT NULL DEFAULT 'recording',
            started_at INTEGER NOT NULL,
            ended_at INTEGER,
            distance_meters REAL NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
          database.execute('''
          CREATE TABLE location_records (
            client_record_id TEXT NOT NULL PRIMARY KEY,
            session_id TEXT NOT NULL REFERENCES tracking_sessions(id) ON DELETE CASCADE,
            recorded_at INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            altitude_m REAL,
            accuracy_m REAL,
            speed_mps REAL,
            heading_deg REAL
          )
        ''');
          database.execute('''
          INSERT INTO tracking_sessions (
            id, started_at, created_at, updated_at
          ) VALUES (
            '123e4567-e89b-42d3-a456-426614174200', 1763805600000,
            1763805600000, 1763805600000
          )
        ''');
          database.execute('''
          INSERT INTO location_records (
            client_record_id, session_id, recorded_at, latitude, longitude
          ) VALUES (
            '123e4567-e89b-42d3-a456-426614174201',
            '123e4567-e89b-42d3-a456-426614174200', 1763805601000, 37, -122
          )
        ''');
          database.execute('PRAGMA user_version = 1');
        },
      );
      final database = storage.AppDatabase.forTesting(executor);

      final queue = await DriftSyncLocalStore(database).getQueueStats();

      expect(queue.pendingCount, 1);
      expect(queue.syncedCount, 0);
      await database.close();
    },
  );
}

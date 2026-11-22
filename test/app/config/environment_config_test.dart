import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/app/config/environment_config.dart';

void main() {
  group('EnvironmentConfig', () {
    test('defaults to development without backend configuration', () {
      final config = EnvironmentConfig.fromMap(const {});

      expect(config.appEnvironment, 'development');
      expect(config.isProduction, isFalse);
      expect(config.isSupabaseConfigured, isFalse);
      expect(config.syncBackend, 'mock_rest');
      expect(config.usesMockRestSync, isTrue);
      expect(config.usesSupabaseSync, isFalse);
      expect(config.syncBatchSize, 100);
      expect(
        config.mapTileUrlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
    });

    test('accepts a complete public Supabase configuration', () {
      final config = EnvironmentConfig.fromMap(const {
        'APP_ENV': 'staging',
        'SYNC_BACKEND': 'supabase',
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_example',
      });

      expect(config.appEnvironment, 'staging');
      expect(config.isSupabaseConfigured, isTrue);
      expect(config.usesSupabaseSync, isTrue);
    });

    test('rejects partial Supabase configuration', () {
      expect(
        () => EnvironmentConfig.fromMap(const {
          'SUPABASE_URL': 'https://example.supabase.co',
        }),
        throwsFormatException,
      );
    });

    test('validates synchronization backend configuration', () {
      expect(
        () => EnvironmentConfig.fromMap(const {'SYNC_BACKEND': 'unknown'}),
        throwsFormatException,
      );
      expect(
        () => EnvironmentConfig.fromMap(const {'SYNC_BACKEND': 'supabase'}),
        throwsFormatException,
      );
      expect(
        () => EnvironmentConfig.fromMap(const {
          'APP_ENV': 'production',
          'SYNC_BACKEND': 'mock_rest',
        }),
        throwsFormatException,
      );
    });

    test('rejects unsupported environments and malformed URLs', () {
      expect(
        () => EnvironmentConfig.fromMap(const {'APP_ENV': 'prod'}),
        throwsFormatException,
      );
      expect(
        () => EnvironmentConfig.fromMap(const {
          'SUPABASE_URL': 'file:///tmp/backend',
          'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_example',
        }),
        throwsFormatException,
      );
    });

    test('configures a bounded synchronization batch size', () {
      final config = EnvironmentConfig.fromMap(const {
        'SYNC_BATCH_SIZE': '250',
      });
      expect(config.syncBatchSize, 250);
      expect(
        () => EnvironmentConfig.fromMap(const {'SYNC_BATCH_SIZE': '501'}),
        throwsFormatException,
      );
    });

    test('allows switching the OSM-compatible raster tile template', () {
      final config = EnvironmentConfig.fromMap(const {
        'OSM_TILE_URL_TEMPLATE': 'https://tiles.example/{z}/{x}/{y}.png',
      });
      expect(
        config.mapTileUrlTemplate,
        'https://tiles.example/{z}/{x}/{y}.png',
      );
      expect(
        () => EnvironmentConfig.fromMap(const {
          'OSM_TILE_URL_TEMPLATE': 'https://tiles.example/static.png',
        }),
        throwsFormatException,
      );
    });
  });
}

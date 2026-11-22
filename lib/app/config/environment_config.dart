class EnvironmentConfig {
  const EnvironmentConfig({
    required this.appEnvironment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.syncBackend,
    required this.useSimulatedLocation,
    required this.syncBatchSize,
    required this.mapTileUrlTemplate,
  });

  final String appEnvironment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String syncBackend;
  final bool useSimulatedLocation;
  final int syncBatchSize;
  final String mapTileUrlTemplate;

  bool get isProduction => appEnvironment == 'production';
  bool get isSupabaseConfigured => supabaseUrl.isNotEmpty;
  bool get usesSupabaseSync => syncBackend == 'supabase';
  bool get usesMockRestSync => syncBackend == 'mock_rest';

  factory EnvironmentConfig.fromMap(Map<String, String> values) {
    final appEnvironment =
        values['APP_ENV']?.trim().toLowerCase() ?? 'development';
    const supportedEnvironments = {'development', 'staging', 'production'};
    if (!supportedEnvironments.contains(appEnvironment)) {
      throw FormatException('Unsupported APP_ENV: $appEnvironment');
    }

    final supabaseUrl = values['SUPABASE_URL']?.trim() ?? '';
    final supabasePublishableKey =
        values['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
    final syncBackend =
        values['SYNC_BACKEND']?.trim().toLowerCase() ?? 'mock_rest';
    if (syncBackend != 'mock_rest' && syncBackend != 'supabase') {
      throw const FormatException(
        'SYNC_BACKEND must be mock_rest or supabase.',
      );
    }
    final useSimulatedLocation = (values['USE_SIMULATED_LOCATION'] ?? 'false')
        .trim()
        .toLowerCase();
    if (useSimulatedLocation != 'true' && useSimulatedLocation != 'false') {
      throw const FormatException(
        'USE_SIMULATED_LOCATION must be true or false.',
      );
    }
    if (appEnvironment == 'production' && useSimulatedLocation == 'true') {
      throw const FormatException(
        'Simulated location is not available in production.',
      );
    }
    final syncBatchSize = int.tryParse(values['SYNC_BATCH_SIZE'] ?? '100');
    if (syncBatchSize == null || syncBatchSize < 1 || syncBatchSize > 500) {
      throw const FormatException('SYNC_BATCH_SIZE must be from 1 to 500.');
    }
    if (supabaseUrl.isEmpty != supabasePublishableKey.isEmpty) {
      throw const FormatException(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set together.',
      );
    }
    if (syncBackend == 'supabase' && supabaseUrl.isEmpty) {
      throw const FormatException(
        'Supabase sync requires SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    if (appEnvironment == 'production' && syncBackend == 'mock_rest') {
      throw const FormatException(
        'The mock REST backend is only available outside production.',
      );
    }

    final mapTileUrlTemplate =
        values['OSM_TILE_URL_TEMPLATE']?.trim().isNotEmpty == true
        ? values['OSM_TILE_URL_TEMPLATE']!.trim()
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final mapTileUri = Uri.tryParse(
      mapTileUrlTemplate.replaceAllMapped(RegExp(r'\{[^}]+\}'), (_) => '0'),
    );
    if (mapTileUri == null ||
        (mapTileUri.scheme != 'https' && mapTileUri.scheme != 'http') ||
        mapTileUri.host.isEmpty ||
        !mapTileUrlTemplate.contains('{z}') ||
        !mapTileUrlTemplate.contains('{x}') ||
        !mapTileUrlTemplate.contains('{y}')) {
      throw const FormatException(
        'OSM_TILE_URL_TEMPLATE must be an HTTP URL with {z}, {x}, and {y}.',
      );
    }

    if (supabaseUrl.isNotEmpty) {
      final uri = Uri.tryParse(supabaseUrl);
      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        throw const FormatException('SUPABASE_URL must be a valid HTTP URL.');
      }
    }

    return EnvironmentConfig(
      appEnvironment: appEnvironment,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      syncBackend: syncBackend,
      useSimulatedLocation: useSimulatedLocation == 'true',
      syncBatchSize: syncBatchSize,
      mapTileUrlTemplate: mapTileUrlTemplate,
    );
  }
}

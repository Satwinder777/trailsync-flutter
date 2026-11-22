import 'dart:async';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/config/environment_config.dart';
import '../../../tracking/domain/entities/location_record.dart';
import '../../../tracking/domain/entities/tracking_session.dart';
import '../../domain/entities/sync_record_acknowledgement.dart';
import '../../domain/repositories/sync_remote_data_source.dart';
import '../../domain/services/sync_remote_failure.dart';

class SupabaseSyncRemoteDataSource implements SyncRemoteDataSource {
  SupabaseSyncRemoteDataSource({
    required EnvironmentConfig environment,
    required Dio dio,
    SupabaseClient? client,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _environment = environment,
       _dio = dio,
       _client = client;

  final EnvironmentConfig _environment;
  final Dio _dio;
  final SupabaseClient? _client;
  final Duration requestTimeout;

  @override
  Future<bool> isBackendReachable() async {
    _ensureConfigured();
    final healthUri = Uri.parse(
      '${_environment.supabaseUrl.replaceFirst(RegExp(r'/+$'), '')}'
      '/auth/v1/health',
    );
    try {
      final response = await _dio.getUri<dynamic>(
        healthUri,
        options: Options(
          headers: {'apikey': _environment.supabasePublishableKey},
          validateStatus: (status) => status != null,
          responseType: ResponseType.plain,
        ),
      );
      final status = response.statusCode;
      // HTTP responses below 500 prove that the configured backend endpoint
      // answered. A 429 is reachable, but the subsequent request will back off.
      return status != null && status >= 200 && status < 500;
    } on DioException catch (error) {
      throw _mapDioFailure(error);
    } on TimeoutException {
      throw const SyncRemoteFailure(
        SyncRemoteFailureKind.timeout,
        'The backend reachability check timed out.',
      );
    }
  }

  @override
  Future<List<SyncRecordAcknowledgement>> uploadBatch({
    required TrackingSession session,
    required List<LocationRecord> records,
  }) async {
    _ensureConfigured();
    final client = _client!;
    final user = client.auth.currentUser;
    if (user == null) {
      throw const SyncRemoteFailure(
        SyncRemoteFailureKind.authentication,
        'Sign in to synchronize saved trails.',
      );
    }

    try {
      await _ensureRemoteSession(client, user.id, session);

      final payload = records.map(_recordPayload).toList(growable: false);
      final rawResponse = await client
          .rpc<List<dynamic>>(
            'sync_location_records',
            params: {'p_session_id': session.id, 'p_records': payload},
          )
          .timeout(requestTimeout);
      return _parseAcknowledgements(rawResponse);
    } on SyncRemoteFailure {
      rethrow;
    } on TimeoutException {
      throw const SyncRemoteFailure(
        SyncRemoteFailureKind.timeout,
        'The synchronization request timed out.',
      );
    } on AuthException {
      throw const SyncRemoteFailure(
        SyncRemoteFailureKind.authentication,
        'Your sign-in has expired. Sign in again to synchronize.',
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestFailure(error);
    } catch (_) {
      throw const SyncRemoteFailure(
        SyncRemoteFailureKind.network,
        'The synchronization request could not be completed.',
      );
    }
  }

  Future<void> _ensureRemoteSession(
    SupabaseClient client,
    String userId,
    TrackingSession session,
  ) async {
    final sessions = client.from('tracking_sessions');
    var existing = await sessions
        .select('id')
        .eq('id', session.id)
        .maybeSingle()
        .timeout(requestTimeout);

    if (existing == null) {
      try {
        await sessions
            .insert({
              'id': session.id,
              'user_id': userId,
              'title': session.title,
              'status': session.status.name,
              'started_at': session.startedAt.toUtc().toIso8601String(),
              'ended_at': session.endedAt?.toUtc().toIso8601String(),
              'distance_meters': session.distanceMeters,
            })
            .timeout(requestTimeout);
        return;
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        existing = await sessions
            .select('id')
            .eq('id', session.id)
            .maybeSingle()
            .timeout(requestTimeout);
        if (existing == null) {
          throw const SyncRemoteFailure(
            SyncRemoteFailureKind.authentication,
            'This saved session belongs to a different account.',
          );
        }
      }
    }

    // The migration intentionally restricts updates to mutable session fields.
    await sessions
        .update({
          'title': session.title,
          'status': session.status.name,
          'ended_at': session.endedAt?.toUtc().toIso8601String(),
          'distance_meters': session.distanceMeters,
        })
        .eq('id', session.id)
        .timeout(requestTimeout);
  }

  Map<String, Object?> _recordPayload(LocationRecord record) => {
    'record_id': record.clientRecordId,
    'recorded_at': record.recordedAt.toUtc().toIso8601String(),
    'latitude': record.latitude,
    'longitude': record.longitude,
    'altitude_m': record.altitudeM,
    'accuracy_m': record.accuracyM,
    'speed_mps': record.speedMps,
    'heading_deg': record.headingDeg,
  };

  List<SyncRecordAcknowledgement> _parseAcknowledgements(Object? response) {
    if (response is! List) {
      throw const FormatException('The sync RPC returned an invalid response.');
    }

    return response
        .map((item) {
          if (item is! Map) {
            throw const FormatException(
              'The sync RPC returned an invalid record acknowledgement.',
            );
          }
          final id = item['client_record_id'];
          final rawStatus = item['acknowledgement'];
          final errorCode = item['error_code'];
          final remoteId = item['location_record_id'];
          if (id is! String || rawStatus is! String) {
            throw const FormatException(
              'The sync RPC acknowledgement is missing required fields.',
            );
          }
          final status = switch (rawStatus) {
            'accepted' => SyncAcknowledgementStatus.accepted,
            'duplicate' => SyncAcknowledgementStatus.duplicate,
            'rejected' => SyncAcknowledgementStatus.rejected,
            _ => throw FormatException(
              'Unknown acknowledgement status: $rawStatus',
            ),
          };
          return SyncRecordAcknowledgement(
            clientRecordId: id,
            status: status,
            errorCode: errorCode is String ? errorCode : null,
            remoteRecordId: remoteId is String ? remoteId : null,
          );
        })
        .toList(growable: false);
  }

  void _ensureConfigured() {
    if (!_environment.isSupabaseConfigured || _client == null) {
      throw const SyncRemoteFailure(
        SyncRemoteFailureKind.configuration,
        'Add the Supabase URL and publishable key to the local environment file.',
      );
    }
  }

  SyncRemoteFailure _mapPostgrestFailure(PostgrestException error) {
    final code = error.code;
    if (code == '401' ||
        code == '403' ||
        code == '42501' ||
        code == 'PGRST301') {
      return const SyncRemoteFailure(
        SyncRemoteFailureKind.authentication,
        'Your sign-in does not have access to synchronize these records.',
      );
    }
    if (code == '429') {
      return const SyncRemoteFailure(
        SyncRemoteFailureKind.rateLimited,
        'The backend is rate limiting synchronization. Records are queued to retry.',
      );
    }
    if (code == 'PGRST202' || code == 'PGRST205' || code == '42P01') {
      return const SyncRemoteFailure(
        SyncRemoteFailureKind.configuration,
        'Apply the TrailSync Supabase migration before synchronizing.',
      );
    }
    if (code == '408') {
      return const SyncRemoteFailure(
        SyncRemoteFailureKind.timeout,
        'The synchronization request timed out.',
      );
    }
    if (code == '502' || code == '503' || code == '504') {
      return const SyncRemoteFailure(
        SyncRemoteFailureKind.unavailable,
        'The backend is temporarily unavailable. Records are queued to retry.',
      );
    }
    return const SyncRemoteFailure(
      SyncRemoteFailureKind.server,
      'The backend rejected the synchronization request.',
    );
  }

  SyncRemoteFailure _mapDioFailure(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const SyncRemoteFailure(
      SyncRemoteFailureKind.timeout,
      'The backend reachability check timed out.',
    ),
    _ => const SyncRemoteFailure(
      SyncRemoteFailureKind.network,
      'The backend could not be reached.',
    ),
  };
}

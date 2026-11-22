import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../tracking/domain/entities/location_record.dart';
import '../../../tracking/domain/entities/tracking_session.dart';
import '../../domain/entities/sync_record_acknowledgement.dart';
import '../../domain/repositories/sync_remote_data_source.dart';

/// A deterministic, in-process REST mock for the assessment/demo workflow.
///
/// Requests use Dio, JSON payloads, and REST-shaped endpoints. An interceptor
/// acts as the mock server so a reviewer does not need a separate backend.
class MockRestSyncRemoteDataSource implements SyncRemoteDataSource {
  MockRestSyncRemoteDataSource()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://mock-api.trailsync.invalid/v1',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      ) {
    _dio.interceptors.add(_MockRestApiInterceptor());
  }

  final Dio _dio;

  @override
  Future<bool> isBackendReachable() async {
    final response = await _dio.get<Map<String, Object?>>('/health');
    return response.statusCode == 200 && response.data?['status'] == 'ok';
  }

  @override
  Future<List<SyncRecordAcknowledgement>> uploadBatch({
    required TrackingSession session,
    required List<LocationRecord> records,
  }) async {
    if (records.isEmpty) return const [];

    final sessionPath = '/sessions/${Uri.encodeComponent(session.id)}';
    await _dio.put<void>(
      sessionPath,
      data: {
        'id': session.id,
        'title': session.title,
        'status': session.status.name,
        'started_at': session.startedAt.toUtc().toIso8601String(),
        'ended_at': session.endedAt?.toUtc().toIso8601String(),
        'distance_meters': session.distanceMeters,
      },
    );

    final response = await _dio.post<List<dynamic>>(
      '$sessionPath/location-records:batch',
      data: {'records': records.map(_recordPayload).toList(growable: false)},
    );
    final acknowledgements = response.data;
    if (acknowledgements == null) {
      throw const FormatException('Mock REST API returned an empty response.');
    }

    return acknowledgements.map(_parseAcknowledgement).toList(growable: false);
  }

  Map<String, Object?> _recordPayload(LocationRecord record) => {
    'client_record_id': record.clientRecordId,
    'session_id': record.sessionId,
    'recorded_at': record.recordedAt.toUtc().toIso8601String(),
    'latitude': record.latitude,
    'longitude': record.longitude,
    'altitude_m': record.altitudeM,
    'accuracy_m': record.accuracyM,
    'speed_mps': record.speedMps,
    'heading_deg': record.headingDeg,
  };

  SyncRecordAcknowledgement _parseAcknowledgement(Object? raw) {
    if (raw is! Map) {
      throw const FormatException(
        'Mock REST API returned an invalid acknowledgement.',
      );
    }
    final id = raw['client_record_id'];
    final status = raw['acknowledgement'];
    if (id is! String || status is! String) {
      throw const FormatException(
        'Mock REST API acknowledgement is missing required fields.',
      );
    }
    return SyncRecordAcknowledgement(
      clientRecordId: id,
      status: switch (status) {
        'accepted' => SyncAcknowledgementStatus.accepted,
        'duplicate' => SyncAcknowledgementStatus.duplicate,
        'rejected' => SyncAcknowledgementStatus.rejected,
        _ => throw FormatException(
          'Unknown mock REST acknowledgement: $status',
        ),
      },
      errorCode: raw['error_code'] is String
          ? raw['error_code'] as String
          : null,
      remoteRecordId: raw['location_record_id'] is String
          ? raw['location_record_id'] as String
          : null,
    );
  }

  void close() => _dio.close(force: true);
}

class _MockRestApiInterceptor extends Interceptor {
  final Set<String> _sessions = {};
  final Map<String, String> _recordOwners = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;
    final method = options.method.toUpperCase();

    if (method == 'GET' && path.endsWith('/health')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'ok'},
        ),
      );
      return;
    }

    final batchPath = RegExp(
      r'/sessions/([^/]+)/location-records:batch$',
    ).firstMatch(path);
    if (method == 'POST' && batchPath != null) {
      _handleBatch(options, batchPath.group(1)!, handler);
      return;
    }

    final sessionPath = RegExp(r'/sessions/([^/]+)$').firstMatch(path);
    if (method == 'PUT' && sessionPath != null) {
      _sessions.add(Uri.decodeComponent(sessionPath.group(1)!));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'stored': true},
        ),
      );
      return;
    }

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 404,
        data: {'error': 'route_not_found'},
      ),
    );
  }

  void _handleBatch(
    RequestOptions options,
    String rawSessionId,
    RequestInterceptorHandler handler,
  ) {
    final sessionId = Uri.decodeComponent(rawSessionId);
    if (!_sessions.contains(sessionId)) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 404,
          data: {'error': 'session_not_found'},
        ),
      );
      return;
    }

    final request = _decodeMap(options.data);
    final rawRecords = request['records'];
    if (rawRecords is! List) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 400,
          data: {'error': 'records_required'},
        ),
      );
      return;
    }

    final acknowledgements = <Map<String, Object?>>[];
    for (final rawRecord in rawRecords) {
      final record = _decodeMap(rawRecord);
      final id = record['client_record_id'];
      if (id is! String || id.isEmpty) {
        acknowledgements.add({
          'client_record_id': id is String ? id : '',
          'acknowledgement': 'rejected',
          'error_code': 'record_id_required',
        });
        continue;
      }

      final existingSession = _recordOwners[id];
      if (existingSession != null) {
        acknowledgements.add({
          'client_record_id': id,
          'acknowledgement': existingSession == sessionId
              ? 'duplicate'
              : 'rejected',
          'location_record_id': id,
          if (existingSession != sessionId) 'error_code': 'record_id_conflict',
        });
        continue;
      }

      final latitude = record['latitude'];
      final longitude = record['longitude'];
      if (record['session_id'] != sessionId ||
          latitude is! num ||
          longitude is! num ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        acknowledgements.add({
          'client_record_id': id,
          'acknowledgement': 'rejected',
          'error_code': 'invalid_location',
        });
        continue;
      }

      _recordOwners[id] = sessionId;
      acknowledgements.add({
        'client_record_id': id,
        'acknowledgement': 'accepted',
        'location_record_id': id,
      });
    }

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: acknowledgements,
      ),
    );
  }

  Map<String, Object?> _decodeMap(Object? value) {
    final decoded = value is String ? jsonDecode(value) : value;
    if (decoded is Map) {
      return decoded.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }
}

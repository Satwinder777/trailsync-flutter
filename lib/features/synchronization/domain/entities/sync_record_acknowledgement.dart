import 'package:equatable/equatable.dart';

enum SyncAcknowledgementStatus { accepted, duplicate, rejected }

class SyncRecordAcknowledgement extends Equatable {
  const SyncRecordAcknowledgement({
    required this.clientRecordId,
    required this.status,
    this.errorCode,
    this.remoteRecordId,
  });

  final String clientRecordId;
  final SyncAcknowledgementStatus status;
  final String? errorCode;
  final String? remoteRecordId;

  @override
  List<Object?> get props => [
    clientRecordId,
    status,
    errorCode,
    remoteRecordId,
  ];
}

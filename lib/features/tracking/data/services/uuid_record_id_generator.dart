import 'package:uuid/uuid.dart';

import '../../domain/services/record_id_generator.dart';

class UuidRecordIdGenerator implements RecordIdGenerator {
  UuidRecordIdGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  String create() => _uuid.v4();
}

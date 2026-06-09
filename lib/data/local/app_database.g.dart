// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StudentEmbeddingsTable extends StudentEmbeddings
    with TableInfo<$StudentEmbeddingsTable, StudentEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentEmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentNameMeta =
      const VerificationMeta('studentName');
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
      'student_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentRollNumberMeta =
      const VerificationMeta('studentRollNumber');
  @override
  late final GeneratedColumn<String> studentRollNumber =
      GeneratedColumn<String>('student_roll_number', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _embeddingMeta =
      const VerificationMeta('embedding');
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
      'embedding', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _enrolledAtMeta =
      const VerificationMeta('enrolledAt');
  @override
  late final GeneratedColumn<int> enrolledAt = GeneratedColumn<int>(
      'enrolled_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, studentName, studentRollNumber, embedding, enrolledAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_embeddings';
  @override
  VerificationContext validateIntegrity(Insertable<StudentEmbedding> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_name')) {
      context.handle(
          _studentNameMeta,
          studentName.isAcceptableOrUnknown(
              data['student_name']!, _studentNameMeta));
    } else if (isInserting) {
      context.missing(_studentNameMeta);
    }
    if (data.containsKey('student_roll_number')) {
      context.handle(
          _studentRollNumberMeta,
          studentRollNumber.isAcceptableOrUnknown(
              data['student_roll_number']!, _studentRollNumberMeta));
    }
    if (data.containsKey('embedding')) {
      context.handle(_embeddingMeta,
          embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta));
    } else if (isInserting) {
      context.missing(_embeddingMeta);
    }
    if (data.containsKey('enrolled_at')) {
      context.handle(
          _enrolledAtMeta,
          enrolledAt.isAcceptableOrUnknown(
              data['enrolled_at']!, _enrolledAtMeta));
    } else if (isInserting) {
      context.missing(_enrolledAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentEmbedding(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      studentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_name'])!,
      studentRollNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}student_roll_number']),
      embedding: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}embedding'])!,
      enrolledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}enrolled_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $StudentEmbeddingsTable createAlias(String alias) {
    return $StudentEmbeddingsTable(attachedDatabase, alias);
  }
}

class StudentEmbedding extends DataClass
    implements Insertable<StudentEmbedding> {
  final String id;
  final String studentName;
  final String? studentRollNumber;
  final Uint8List embedding;
  final int enrolledAt;
  final bool synced;
  const StudentEmbedding(
      {required this.id,
      required this.studentName,
      this.studentRollNumber,
      required this.embedding,
      required this.enrolledAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_name'] = Variable<String>(studentName);
    if (!nullToAbsent || studentRollNumber != null) {
      map['student_roll_number'] = Variable<String>(studentRollNumber);
    }
    map['embedding'] = Variable<Uint8List>(embedding);
    map['enrolled_at'] = Variable<int>(enrolledAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  StudentEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return StudentEmbeddingsCompanion(
      id: Value(id),
      studentName: Value(studentName),
      studentRollNumber: studentRollNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(studentRollNumber),
      embedding: Value(embedding),
      enrolledAt: Value(enrolledAt),
      synced: Value(synced),
    );
  }

  factory StudentEmbedding.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentEmbedding(
      id: serializer.fromJson<String>(json['id']),
      studentName: serializer.fromJson<String>(json['studentName']),
      studentRollNumber:
          serializer.fromJson<String?>(json['studentRollNumber']),
      embedding: serializer.fromJson<Uint8List>(json['embedding']),
      enrolledAt: serializer.fromJson<int>(json['enrolledAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentName': serializer.toJson<String>(studentName),
      'studentRollNumber': serializer.toJson<String?>(studentRollNumber),
      'embedding': serializer.toJson<Uint8List>(embedding),
      'enrolledAt': serializer.toJson<int>(enrolledAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  StudentEmbedding copyWith(
          {String? id,
          String? studentName,
          Value<String?> studentRollNumber = const Value.absent(),
          Uint8List? embedding,
          int? enrolledAt,
          bool? synced}) =>
      StudentEmbedding(
        id: id ?? this.id,
        studentName: studentName ?? this.studentName,
        studentRollNumber: studentRollNumber.present
            ? studentRollNumber.value
            : this.studentRollNumber,
        embedding: embedding ?? this.embedding,
        enrolledAt: enrolledAt ?? this.enrolledAt,
        synced: synced ?? this.synced,
      );
  StudentEmbedding copyWithCompanion(StudentEmbeddingsCompanion data) {
    return StudentEmbedding(
      id: data.id.present ? data.id.value : this.id,
      studentName:
          data.studentName.present ? data.studentName.value : this.studentName,
      studentRollNumber: data.studentRollNumber.present
          ? data.studentRollNumber.value
          : this.studentRollNumber,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      enrolledAt:
          data.enrolledAt.present ? data.enrolledAt.value : this.enrolledAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentEmbedding(')
          ..write('id: $id, ')
          ..write('studentName: $studentName, ')
          ..write('studentRollNumber: $studentRollNumber, ')
          ..write('embedding: $embedding, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentName, studentRollNumber,
      $driftBlobEquality.hash(embedding), enrolledAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentEmbedding &&
          other.id == this.id &&
          other.studentName == this.studentName &&
          other.studentRollNumber == this.studentRollNumber &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.enrolledAt == this.enrolledAt &&
          other.synced == this.synced);
}

class StudentEmbeddingsCompanion extends UpdateCompanion<StudentEmbedding> {
  final Value<String> id;
  final Value<String> studentName;
  final Value<String?> studentRollNumber;
  final Value<Uint8List> embedding;
  final Value<int> enrolledAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const StudentEmbeddingsCompanion({
    this.id = const Value.absent(),
    this.studentName = const Value.absent(),
    this.studentRollNumber = const Value.absent(),
    this.embedding = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentEmbeddingsCompanion.insert({
    required String id,
    required String studentName,
    this.studentRollNumber = const Value.absent(),
    required Uint8List embedding,
    required int enrolledAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        studentName = Value(studentName),
        embedding = Value(embedding),
        enrolledAt = Value(enrolledAt);
  static Insertable<StudentEmbedding> custom({
    Expression<String>? id,
    Expression<String>? studentName,
    Expression<String>? studentRollNumber,
    Expression<Uint8List>? embedding,
    Expression<int>? enrolledAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentName != null) 'student_name': studentName,
      if (studentRollNumber != null) 'student_roll_number': studentRollNumber,
      if (embedding != null) 'embedding': embedding,
      if (enrolledAt != null) 'enrolled_at': enrolledAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentEmbeddingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? studentName,
      Value<String?>? studentRollNumber,
      Value<Uint8List>? embedding,
      Value<int>? enrolledAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return StudentEmbeddingsCompanion(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      embedding: embedding ?? this.embedding,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (studentRollNumber.present) {
      map['student_roll_number'] = Variable<String>(studentRollNumber.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (enrolledAt.present) {
      map['enrolled_at'] = Variable<int>(enrolledAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentEmbeddingsCompanion(')
          ..write('id: $id, ')
          ..write('studentName: $studentName, ')
          ..write('studentRollNumber: $studentRollNumber, ')
          ..write('embedding: $embedding, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceLogsTable extends AttendanceLogs
    with TableInfo<$AttendanceLogsTable, AttendanceLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionUuidMeta =
      const VerificationMeta('sessionUuid');
  @override
  late final GeneratedColumn<String> sessionUuid = GeneratedColumn<String>(
      'session_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teacherNameMeta =
      const VerificationMeta('teacherName');
  @override
  late final GeneratedColumn<String> teacherName = GeneratedColumn<String>(
      'teacher_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roomCodeMeta =
      const VerificationMeta('roomCode');
  @override
  late final GeneratedColumn<String> roomCode = GeneratedColumn<String>(
      'room_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _proximityVerifiedMeta =
      const VerificationMeta('proximityVerified');
  @override
  late final GeneratedColumn<bool> proximityVerified = GeneratedColumn<bool>(
      'proximity_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("proximity_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _faceVerifiedMeta =
      const VerificationMeta('faceVerified');
  @override
  late final GeneratedColumn<bool> faceVerified = GeneratedColumn<bool>(
      'face_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("face_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _codeVerifiedMeta =
      const VerificationMeta('codeVerified');
  @override
  late final GeneratedColumn<bool> codeVerified = GeneratedColumn<bool>(
      'code_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("code_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<int> capturedAt = GeneratedColumn<int>(
      'captured_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        studentId,
        sessionUuid,
        teacherName,
        roomCode,
        proximityVerified,
        faceVerified,
        codeVerified,
        capturedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AttendanceLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('session_uuid')) {
      context.handle(
          _sessionUuidMeta,
          sessionUuid.isAcceptableOrUnknown(
              data['session_uuid']!, _sessionUuidMeta));
    } else if (isInserting) {
      context.missing(_sessionUuidMeta);
    }
    if (data.containsKey('teacher_name')) {
      context.handle(
          _teacherNameMeta,
          teacherName.isAcceptableOrUnknown(
              data['teacher_name']!, _teacherNameMeta));
    } else if (isInserting) {
      context.missing(_teacherNameMeta);
    }
    if (data.containsKey('room_code')) {
      context.handle(_roomCodeMeta,
          roomCode.isAcceptableOrUnknown(data['room_code']!, _roomCodeMeta));
    } else if (isInserting) {
      context.missing(_roomCodeMeta);
    }
    if (data.containsKey('proximity_verified')) {
      context.handle(
          _proximityVerifiedMeta,
          proximityVerified.isAcceptableOrUnknown(
              data['proximity_verified']!, _proximityVerifiedMeta));
    }
    if (data.containsKey('face_verified')) {
      context.handle(
          _faceVerifiedMeta,
          faceVerified.isAcceptableOrUnknown(
              data['face_verified']!, _faceVerifiedMeta));
    }
    if (data.containsKey('code_verified')) {
      context.handle(
          _codeVerifiedMeta,
          codeVerified.isAcceptableOrUnknown(
              data['code_verified']!, _codeVerifiedMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      sessionUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_uuid'])!,
      teacherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher_name'])!,
      roomCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_code'])!,
      proximityVerified: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}proximity_verified'])!,
      faceVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}face_verified'])!,
      codeVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}code_verified'])!,
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}captured_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $AttendanceLogsTable createAlias(String alias) {
    return $AttendanceLogsTable(attachedDatabase, alias);
  }
}

class AttendanceLog extends DataClass implements Insertable<AttendanceLog> {
  final String id;
  final String studentId;
  final String sessionUuid;
  final String teacherName;
  final String roomCode;
  final bool proximityVerified;
  final bool faceVerified;
  final bool codeVerified;
  final int capturedAt;
  final bool synced;
  const AttendanceLog(
      {required this.id,
      required this.studentId,
      required this.sessionUuid,
      required this.teacherName,
      required this.roomCode,
      required this.proximityVerified,
      required this.faceVerified,
      required this.codeVerified,
      required this.capturedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_id'] = Variable<String>(studentId);
    map['session_uuid'] = Variable<String>(sessionUuid);
    map['teacher_name'] = Variable<String>(teacherName);
    map['room_code'] = Variable<String>(roomCode);
    map['proximity_verified'] = Variable<bool>(proximityVerified);
    map['face_verified'] = Variable<bool>(faceVerified);
    map['code_verified'] = Variable<bool>(codeVerified);
    map['captured_at'] = Variable<int>(capturedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AttendanceLogsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceLogsCompanion(
      id: Value(id),
      studentId: Value(studentId),
      sessionUuid: Value(sessionUuid),
      teacherName: Value(teacherName),
      roomCode: Value(roomCode),
      proximityVerified: Value(proximityVerified),
      faceVerified: Value(faceVerified),
      codeVerified: Value(codeVerified),
      capturedAt: Value(capturedAt),
      synced: Value(synced),
    );
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceLog(
      id: serializer.fromJson<String>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      sessionUuid: serializer.fromJson<String>(json['sessionUuid']),
      teacherName: serializer.fromJson<String>(json['teacherName']),
      roomCode: serializer.fromJson<String>(json['roomCode']),
      proximityVerified: serializer.fromJson<bool>(json['proximityVerified']),
      faceVerified: serializer.fromJson<bool>(json['faceVerified']),
      codeVerified: serializer.fromJson<bool>(json['codeVerified']),
      capturedAt: serializer.fromJson<int>(json['capturedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentId': serializer.toJson<String>(studentId),
      'sessionUuid': serializer.toJson<String>(sessionUuid),
      'teacherName': serializer.toJson<String>(teacherName),
      'roomCode': serializer.toJson<String>(roomCode),
      'proximityVerified': serializer.toJson<bool>(proximityVerified),
      'faceVerified': serializer.toJson<bool>(faceVerified),
      'codeVerified': serializer.toJson<bool>(codeVerified),
      'capturedAt': serializer.toJson<int>(capturedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AttendanceLog copyWith(
          {String? id,
          String? studentId,
          String? sessionUuid,
          String? teacherName,
          String? roomCode,
          bool? proximityVerified,
          bool? faceVerified,
          bool? codeVerified,
          int? capturedAt,
          bool? synced}) =>
      AttendanceLog(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        sessionUuid: sessionUuid ?? this.sessionUuid,
        teacherName: teacherName ?? this.teacherName,
        roomCode: roomCode ?? this.roomCode,
        proximityVerified: proximityVerified ?? this.proximityVerified,
        faceVerified: faceVerified ?? this.faceVerified,
        codeVerified: codeVerified ?? this.codeVerified,
        capturedAt: capturedAt ?? this.capturedAt,
        synced: synced ?? this.synced,
      );
  AttendanceLog copyWithCompanion(AttendanceLogsCompanion data) {
    return AttendanceLog(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      sessionUuid:
          data.sessionUuid.present ? data.sessionUuid.value : this.sessionUuid,
      teacherName:
          data.teacherName.present ? data.teacherName.value : this.teacherName,
      roomCode: data.roomCode.present ? data.roomCode.value : this.roomCode,
      proximityVerified: data.proximityVerified.present
          ? data.proximityVerified.value
          : this.proximityVerified,
      faceVerified: data.faceVerified.present
          ? data.faceVerified.value
          : this.faceVerified,
      codeVerified: data.codeVerified.present
          ? data.codeVerified.value
          : this.codeVerified,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLog(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('sessionUuid: $sessionUuid, ')
          ..write('teacherName: $teacherName, ')
          ..write('roomCode: $roomCode, ')
          ..write('proximityVerified: $proximityVerified, ')
          ..write('faceVerified: $faceVerified, ')
          ..write('codeVerified: $codeVerified, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      studentId,
      sessionUuid,
      teacherName,
      roomCode,
      proximityVerified,
      faceVerified,
      codeVerified,
      capturedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceLog &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.sessionUuid == this.sessionUuid &&
          other.teacherName == this.teacherName &&
          other.roomCode == this.roomCode &&
          other.proximityVerified == this.proximityVerified &&
          other.faceVerified == this.faceVerified &&
          other.codeVerified == this.codeVerified &&
          other.capturedAt == this.capturedAt &&
          other.synced == this.synced);
}

class AttendanceLogsCompanion extends UpdateCompanion<AttendanceLog> {
  final Value<String> id;
  final Value<String> studentId;
  final Value<String> sessionUuid;
  final Value<String> teacherName;
  final Value<String> roomCode;
  final Value<bool> proximityVerified;
  final Value<bool> faceVerified;
  final Value<bool> codeVerified;
  final Value<int> capturedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const AttendanceLogsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.sessionUuid = const Value.absent(),
    this.teacherName = const Value.absent(),
    this.roomCode = const Value.absent(),
    this.proximityVerified = const Value.absent(),
    this.faceVerified = const Value.absent(),
    this.codeVerified = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceLogsCompanion.insert({
    required String id,
    required String studentId,
    required String sessionUuid,
    required String teacherName,
    required String roomCode,
    this.proximityVerified = const Value.absent(),
    this.faceVerified = const Value.absent(),
    this.codeVerified = const Value.absent(),
    required int capturedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        studentId = Value(studentId),
        sessionUuid = Value(sessionUuid),
        teacherName = Value(teacherName),
        roomCode = Value(roomCode),
        capturedAt = Value(capturedAt);
  static Insertable<AttendanceLog> custom({
    Expression<String>? id,
    Expression<String>? studentId,
    Expression<String>? sessionUuid,
    Expression<String>? teacherName,
    Expression<String>? roomCode,
    Expression<bool>? proximityVerified,
    Expression<bool>? faceVerified,
    Expression<bool>? codeVerified,
    Expression<int>? capturedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (sessionUuid != null) 'session_uuid': sessionUuid,
      if (teacherName != null) 'teacher_name': teacherName,
      if (roomCode != null) 'room_code': roomCode,
      if (proximityVerified != null) 'proximity_verified': proximityVerified,
      if (faceVerified != null) 'face_verified': faceVerified,
      if (codeVerified != null) 'code_verified': codeVerified,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? studentId,
      Value<String>? sessionUuid,
      Value<String>? teacherName,
      Value<String>? roomCode,
      Value<bool>? proximityVerified,
      Value<bool>? faceVerified,
      Value<bool>? codeVerified,
      Value<int>? capturedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return AttendanceLogsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      sessionUuid: sessionUuid ?? this.sessionUuid,
      teacherName: teacherName ?? this.teacherName,
      roomCode: roomCode ?? this.roomCode,
      proximityVerified: proximityVerified ?? this.proximityVerified,
      faceVerified: faceVerified ?? this.faceVerified,
      codeVerified: codeVerified ?? this.codeVerified,
      capturedAt: capturedAt ?? this.capturedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (sessionUuid.present) {
      map['session_uuid'] = Variable<String>(sessionUuid.value);
    }
    if (teacherName.present) {
      map['teacher_name'] = Variable<String>(teacherName.value);
    }
    if (roomCode.present) {
      map['room_code'] = Variable<String>(roomCode.value);
    }
    if (proximityVerified.present) {
      map['proximity_verified'] = Variable<bool>(proximityVerified.value);
    }
    if (faceVerified.present) {
      map['face_verified'] = Variable<bool>(faceVerified.value);
    }
    if (codeVerified.present) {
      map['code_verified'] = Variable<bool>(codeVerified.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(capturedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('sessionUuid: $sessionUuid, ')
          ..write('teacherName: $teacherName, ')
          ..write('roomCode: $roomCode, ')
          ..write('proximityVerified: $proximityVerified, ')
          ..write('faceVerified: $faceVerified, ')
          ..write('codeVerified: $codeVerified, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StudentEmbeddingsTable studentEmbeddings =
      $StudentEmbeddingsTable(this);
  late final $AttendanceLogsTable attendanceLogs = $AttendanceLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [studentEmbeddings, attendanceLogs];
}

typedef $$StudentEmbeddingsTableCreateCompanionBuilder
    = StudentEmbeddingsCompanion Function({
  required String id,
  required String studentName,
  Value<String?> studentRollNumber,
  required Uint8List embedding,
  required int enrolledAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$StudentEmbeddingsTableUpdateCompanionBuilder
    = StudentEmbeddingsCompanion Function({
  Value<String> id,
  Value<String> studentName,
  Value<String?> studentRollNumber,
  Value<Uint8List> embedding,
  Value<int> enrolledAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$StudentEmbeddingsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentEmbeddingsTable> {
  $$StudentEmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentRollNumber => $composableBuilder(
      column: $table.studentRollNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
      column: $table.embedding, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get enrolledAt => $composableBuilder(
      column: $table.enrolledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$StudentEmbeddingsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentEmbeddingsTable> {
  $$StudentEmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentRollNumber => $composableBuilder(
      column: $table.studentRollNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
      column: $table.embedding, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get enrolledAt => $composableBuilder(
      column: $table.enrolledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$StudentEmbeddingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentEmbeddingsTable> {
  $$StudentEmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => column);

  GeneratedColumn<String> get studentRollNumber => $composableBuilder(
      column: $table.studentRollNumber, builder: (column) => column);

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<int> get enrolledAt => $composableBuilder(
      column: $table.enrolledAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$StudentEmbeddingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudentEmbeddingsTable,
    StudentEmbedding,
    $$StudentEmbeddingsTableFilterComposer,
    $$StudentEmbeddingsTableOrderingComposer,
    $$StudentEmbeddingsTableAnnotationComposer,
    $$StudentEmbeddingsTableCreateCompanionBuilder,
    $$StudentEmbeddingsTableUpdateCompanionBuilder,
    (
      StudentEmbedding,
      BaseReferences<_$AppDatabase, $StudentEmbeddingsTable, StudentEmbedding>
    ),
    StudentEmbedding,
    PrefetchHooks Function()> {
  $$StudentEmbeddingsTableTableManager(
      _$AppDatabase db, $StudentEmbeddingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentEmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentEmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentEmbeddingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> studentName = const Value.absent(),
            Value<String?> studentRollNumber = const Value.absent(),
            Value<Uint8List> embedding = const Value.absent(),
            Value<int> enrolledAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentEmbeddingsCompanion(
            id: id,
            studentName: studentName,
            studentRollNumber: studentRollNumber,
            embedding: embedding,
            enrolledAt: enrolledAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String studentName,
            Value<String?> studentRollNumber = const Value.absent(),
            required Uint8List embedding,
            required int enrolledAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentEmbeddingsCompanion.insert(
            id: id,
            studentName: studentName,
            studentRollNumber: studentRollNumber,
            embedding: embedding,
            enrolledAt: enrolledAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudentEmbeddingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudentEmbeddingsTable,
    StudentEmbedding,
    $$StudentEmbeddingsTableFilterComposer,
    $$StudentEmbeddingsTableOrderingComposer,
    $$StudentEmbeddingsTableAnnotationComposer,
    $$StudentEmbeddingsTableCreateCompanionBuilder,
    $$StudentEmbeddingsTableUpdateCompanionBuilder,
    (
      StudentEmbedding,
      BaseReferences<_$AppDatabase, $StudentEmbeddingsTable, StudentEmbedding>
    ),
    StudentEmbedding,
    PrefetchHooks Function()>;
typedef $$AttendanceLogsTableCreateCompanionBuilder = AttendanceLogsCompanion
    Function({
  required String id,
  required String studentId,
  required String sessionUuid,
  required String teacherName,
  required String roomCode,
  Value<bool> proximityVerified,
  Value<bool> faceVerified,
  Value<bool> codeVerified,
  required int capturedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$AttendanceLogsTableUpdateCompanionBuilder = AttendanceLogsCompanion
    Function({
  Value<String> id,
  Value<String> studentId,
  Value<String> sessionUuid,
  Value<String> teacherName,
  Value<String> roomCode,
  Value<bool> proximityVerified,
  Value<bool> faceVerified,
  Value<bool> codeVerified,
  Value<int> capturedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$AttendanceLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionUuid => $composableBuilder(
      column: $table.sessionUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teacherName => $composableBuilder(
      column: $table.teacherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roomCode => $composableBuilder(
      column: $table.roomCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get proximityVerified => $composableBuilder(
      column: $table.proximityVerified,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get faceVerified => $composableBuilder(
      column: $table.faceVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get codeVerified => $composableBuilder(
      column: $table.codeVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$AttendanceLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionUuid => $composableBuilder(
      column: $table.sessionUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teacherName => $composableBuilder(
      column: $table.teacherName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roomCode => $composableBuilder(
      column: $table.roomCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get proximityVerified => $composableBuilder(
      column: $table.proximityVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get faceVerified => $composableBuilder(
      column: $table.faceVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get codeVerified => $composableBuilder(
      column: $table.codeVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$AttendanceLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get sessionUuid => $composableBuilder(
      column: $table.sessionUuid, builder: (column) => column);

  GeneratedColumn<String> get teacherName => $composableBuilder(
      column: $table.teacherName, builder: (column) => column);

  GeneratedColumn<String> get roomCode =>
      $composableBuilder(column: $table.roomCode, builder: (column) => column);

  GeneratedColumn<bool> get proximityVerified => $composableBuilder(
      column: $table.proximityVerified, builder: (column) => column);

  GeneratedColumn<bool> get faceVerified => $composableBuilder(
      column: $table.faceVerified, builder: (column) => column);

  GeneratedColumn<bool> get codeVerified => $composableBuilder(
      column: $table.codeVerified, builder: (column) => column);

  GeneratedColumn<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AttendanceLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendanceLogsTable,
    AttendanceLog,
    $$AttendanceLogsTableFilterComposer,
    $$AttendanceLogsTableOrderingComposer,
    $$AttendanceLogsTableAnnotationComposer,
    $$AttendanceLogsTableCreateCompanionBuilder,
    $$AttendanceLogsTableUpdateCompanionBuilder,
    (
      AttendanceLog,
      BaseReferences<_$AppDatabase, $AttendanceLogsTable, AttendanceLog>
    ),
    AttendanceLog,
    PrefetchHooks Function()> {
  $$AttendanceLogsTableTableManager(
      _$AppDatabase db, $AttendanceLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> sessionUuid = const Value.absent(),
            Value<String> teacherName = const Value.absent(),
            Value<String> roomCode = const Value.absent(),
            Value<bool> proximityVerified = const Value.absent(),
            Value<bool> faceVerified = const Value.absent(),
            Value<bool> codeVerified = const Value.absent(),
            Value<int> capturedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceLogsCompanion(
            id: id,
            studentId: studentId,
            sessionUuid: sessionUuid,
            teacherName: teacherName,
            roomCode: roomCode,
            proximityVerified: proximityVerified,
            faceVerified: faceVerified,
            codeVerified: codeVerified,
            capturedAt: capturedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String studentId,
            required String sessionUuid,
            required String teacherName,
            required String roomCode,
            Value<bool> proximityVerified = const Value.absent(),
            Value<bool> faceVerified = const Value.absent(),
            Value<bool> codeVerified = const Value.absent(),
            required int capturedAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceLogsCompanion.insert(
            id: id,
            studentId: studentId,
            sessionUuid: sessionUuid,
            teacherName: teacherName,
            roomCode: roomCode,
            proximityVerified: proximityVerified,
            faceVerified: faceVerified,
            codeVerified: codeVerified,
            capturedAt: capturedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttendanceLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendanceLogsTable,
    AttendanceLog,
    $$AttendanceLogsTableFilterComposer,
    $$AttendanceLogsTableOrderingComposer,
    $$AttendanceLogsTableAnnotationComposer,
    $$AttendanceLogsTableCreateCompanionBuilder,
    $$AttendanceLogsTableUpdateCompanionBuilder,
    (
      AttendanceLog,
      BaseReferences<_$AppDatabase, $AttendanceLogsTable, AttendanceLog>
    ),
    AttendanceLog,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StudentEmbeddingsTableTableManager get studentEmbeddings =>
      $$StudentEmbeddingsTableTableManager(_db, _db.studentEmbeddings);
  $$AttendanceLogsTableTableManager get attendanceLogs =>
      $$AttendanceLogsTableTableManager(_db, _db.attendanceLogs);
}

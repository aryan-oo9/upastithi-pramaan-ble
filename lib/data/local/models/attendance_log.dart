// lib/data/local/models/attendance_log.dart

import 'package:drift/drift.dart';

/// Drift table for storing attendance records pending or already synced.
class AttendanceLogs extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get studentId => text().named('student_id')();
  TextColumn get sessionUuid => text().named('session_uuid')();
  TextColumn get teacherName => text().named('teacher_name')();
  TextColumn get roomCode => text().named('room_code')();
  BoolColumn get proximityVerified =>
      boolean().named('proximity_verified').withDefault(const Constant(false))();
  BoolColumn get faceVerified =>
      boolean().named('face_verified').withDefault(const Constant(false))();
  BoolColumn get codeVerified =>
      boolean().named('code_verified').withDefault(const Constant(false))();
  IntColumn get capturedAt => integer().named('captured_at')(); // epoch ms
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
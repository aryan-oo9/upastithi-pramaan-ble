// lib/data/local/app_database.dart

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upastithi_pramaan/data/local/models/attendance_log.dart';
import 'package:upastithi_pramaan/data/local/models/student_embedding.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [StudentEmbeddings, AttendanceLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'upastithi_pramaan_db');
  }

  // ── StudentEmbeddings helpers ──────────────────────────────────────────────

  Future<List<StudentEmbedding>> getAllEmbeddings() =>
      select(studentEmbeddings).get();

  Future<void> upsertEmbedding(StudentEmbeddingsCompanion entry) =>
      into(studentEmbeddings).insertOnConflictUpdate(entry);

  // ── AttendanceLogs helpers ─────────────────────────────────────────────────

  Future<void> insertLog(AttendanceLogsCompanion entry) =>
      into(attendanceLogs).insert(entry);

  Future<List<AttendanceLog>> getPendingSyncLogs() =>
      (select(attendanceLogs)..where((t) => t.synced.equals(false))).get();

  Future<void> markLogSynced(String id) => (update(attendanceLogs)
        ..where((t) => t.id.equals(id)))
      .write(const AttendanceLogsCompanion(synced: Value(true)));
}

// Riverpod provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
// lib/data/local/models/student_embedding.dart

import 'package:drift/drift.dart';

/// Drift table for storing per-student face embeddings (128-d float32 vector
/// serialised as a BLOB).
class StudentEmbeddings extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get studentName => text().named('student_name')();
  TextColumn get studentRollNumber =>
      text().named('student_roll_number').nullable()();
  BlobColumn get embedding => blob()(); // 512 × 4 bytes = 2048 bytes
  IntColumn get enrolledAt => integer().named('enrolled_at')(); // epoch ms
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
// lib/data/models/session_model.dart

class SessionModel {
  const SessionModel({
    required this.id,
    required this.subjectId,
    required this.facultyId,
    required this.active,
    this.twofaCode,
    this.twofaExpiresAt,
    this.subjectName,
    this.subjectCode,
  });

  final String id;
  final String subjectId;
  final String facultyId;
  final bool active;
  final String? twofaCode;
  final DateTime? twofaExpiresAt;
  final String? subjectName;
  final String? subjectCode;

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      facultyId: map['faculty_id'] as String,
      active: map['active'] as bool? ?? false,
      twofaCode: map['twofa_code'] as String?,
      twofaExpiresAt: map['twofa_code_expires_at'] != null
          ? DateTime.parse(map['twofa_code_expires_at'] as String)
          : null,
      subjectName: map['subjects'] != null
          ? (map['subjects'] as Map<String, dynamic>)['name'] as String?
          : null,
      subjectCode: map['subjects'] != null
          ? (map['subjects'] as Map<String, dynamic>)['code'] as String?
          : null,
    );
  }
}
// lib/services/session_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/data/models/session_model.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';

class SessionService {
  SessionService(this._supabase);
  final SupabaseClient _supabase;

  /// Teacher: create a new session in Supabase
  Future<SessionModel> createSession({
    required String facultyId,
    required String subjectId,
    required String initialCode,
  }) async {
    try {
      final expiresAt = DateTime.now().toUtc().add(const Duration(seconds: 50));
      final res = await _supabase.from('sessions').insert({
        'faculty_id': facultyId,
        'subject_id': subjectId,
        'active': true,
        'twofa_code': initialCode,
        'twofa_code_expires_at': expiresAt.toIso8601String(),
      }).select('*, subjects(name, code)').single();

      AppLogger.i('Session created: ${res['id']}');
      return SessionModel.fromMap(res);
    } on PostgrestException catch (e) {
      AppLogger.e('createSession error', e);
      rethrow;
    }
  }

  /// Teacher: update rotating code in Supabase
  Future<void> updateSessionCode({
    required String sessionId,
    required String newCode,
    required DateTime expiresAt,
  }) async {
    try {
      await _supabase.from('sessions').update({
        'twofa_code': newCode,
        'twofa_code_expires_at': expiresAt.toIso8601String(),
      }).eq('id', sessionId);
      AppLogger.d('Session code updated: $newCode');
    } on PostgrestException catch (e) {
      AppLogger.e('updateSessionCode error', e);
    }
  }

  /// Teacher: end session
  Future<void> endSession(String sessionId) async {
    try {
      await _supabase.from('sessions').update({
        'active': false,
        'ended_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
      AppLogger.i('Session ended: $sessionId');
    } on PostgrestException catch (e) {
      AppLogger.e('endSession error', e);
    }
  }

  /// Student: verify a session code
  Future<CodeVerifyResult> verifySessionCode({
    required String sessionId,
    required String enteredCode,
  }) async {
    try {
      final res = await _supabase
          .from('sessions')
          .select('twofa_code, twofa_code_expires_at, active')
          .eq('id', sessionId)
          .single();

      if (res['active'] != true) {
        return CodeVerifyResult.sessionEnded;
      }

      final storedCode = res['twofa_code'] as String?;
      final expiresAt = res['twofa_code_expires_at'] != null
          ? DateTime.parse(res['twofa_code_expires_at'] as String)
          : null;

      if (storedCode == null) return CodeVerifyResult.invalid;
      if (storedCode != enteredCode) return CodeVerifyResult.invalid;
      if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt)) {
        return CodeVerifyResult.expired;
      }

      return CodeVerifyResult.valid;
    } on PostgrestException catch (e) {
      AppLogger.e('verifySessionCode error', e);
      return CodeVerifyResult.error;
    }
  }

  /// Student: get active sessions (for picking which teacher)
  Future<List<SessionModel>> getActiveSessions() async {
    try {
      final res = await _supabase
          .from('sessions')
          .select('*, subjects(name, code)')
          .eq('active', true)
          .order('started_at', ascending: false);

      return (res as List)
          .map((e) => SessionModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      AppLogger.e('getActiveSessions error', e);
      return [];
    }
  }

  /// Student: submit attendance record
  Future<void> submitAttendance({
    required String sessionId,
    required String studentId,
    required bool bleVerified,
    required int bleRssi,
    required bool faceVerified,
    required bool codeVerified,
  }) async {
    try {
      await _supabase.from('attendance_records').upsert({
        'session_id': sessionId,
        'student_id': studentId,
        'ble_verified': bleVerified,
        'ble_rssi': bleRssi,
        'face_verified': faceVerified,
        'mac_verified': codeVerified,
        'marked_at': DateTime.now().toUtc().toIso8601String(),
        'fraud_score': _calculateFraudScore(
            bleVerified: bleVerified,
            faceVerified: faceVerified,
            codeVerified: codeVerified),
      });
      AppLogger.i('Attendance submitted for student $studentId');
    } on PostgrestException catch (e) {
      AppLogger.e('submitAttendance error', e);
      rethrow;
    }
  }

  int _calculateFraudScore({
    required bool bleVerified,
    required bool faceVerified,
    required bool codeVerified,
  }) {
    int score = 0;
    if (!bleVerified) score += 40;
    if (!faceVerified) score += 40;
    if (!codeVerified) score += 20;
    return score;
  }
}

enum CodeVerifyResult { valid, invalid, expired, sessionEnded, error }

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(supabaseClientProvider));
});

final activeSessionProvider = StateProvider<SessionModel?>((ref) => null);
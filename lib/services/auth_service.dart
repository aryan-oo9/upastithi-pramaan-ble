// lib/services/auth_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/data/models/app_user.dart';

class AuthService {
  AuthService(this._supabase);
  final SupabaseClient _supabase;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Login for students using roll number + password
  Future<AppUser> loginStudent({
    required String rollNumber,
    required String password,
  }) async {
    try {
      final studentRes = await _supabase
          .from('students')
          .select('*, users!inner(*)')
          .eq('roll', rollNumber.trim().toUpperCase())
          .single();

      final userMap = studentRes['users'] as Map<String, dynamic>;
      final storedHash = userMap['password_hash'] as String;

      if (_hashPassword(password) != storedHash) {
        throw AuthException('Invalid roll number or password');
      }

      AppLogger.i('Student logged in: $rollNumber');
      return AppUser.fromStudentMap(userMap, studentRes);
    } on PostgrestException catch (e) {
      AppLogger.e('loginStudent DB error', e);
      throw AuthException('Student not found: ${e.message}');
    }
  }

  /// Login for faculty using emp_id + password
  Future<AppUser> loginFaculty({
    required String empId,
    required String password,
  }) async {
    try {
      final facultyRes = await _supabase
          .from('faculty')
          .select('*, users!inner(*)')
          .eq('emp_id', empId.trim())
          .single();

      final userMap = facultyRes['users'] as Map<String, dynamic>;
      final storedHash = userMap['password_hash'] as String;

      if (_hashPassword(password) != storedHash) {
        throw AuthException('Invalid employee ID or password');
      }

      AppLogger.i('Faculty logged in: $empId');
      return AppUser.fromFacultyMap(userMap, facultyRes);
    } on PostgrestException catch (e) {
      AppLogger.e('loginFaculty DB error', e);
      throw AuthException('Faculty not found: ${e.message}');
    }
  }

  /// Login for admin — password only, single admin account
  Future<AppUser> loginAdmin({
    required String password,
  }) async {
    try {
      final userRes = await _supabase
          .from('users')
          .select()
          .eq('role', 'admin')
          .single();

      final storedHash = userRes['password_hash'] as String;

      if (_hashPassword(password) != storedHash) {
        throw AuthException('Invalid admin password');
      }

      AppLogger.i('Admin logged in');
      return AppUser(
        id: userRes['id'] as String,
        role: UserRole.admin,
        name: userRes['name'] as String,
      );
    } on PostgrestException catch (e) {
      AppLogger.e('loginAdmin DB error', e);
      throw AuthException('Admin login failed: ${e.message}');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

// ── Providers ──────────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final currentUserProvider = StateProvider<AppUser?>((ref) => null);
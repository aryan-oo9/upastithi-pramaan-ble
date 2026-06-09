// lib/core/constants/supabase_constants.dart

class SupabaseConstants {
  SupabaseConstants._();

  // 🔴 Replace these with your actual Supabase project values
  static const String supabaseUrl = 'https://lewioejhrlckpodrmtcv.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxld2lvZWpocmxja3BvZHJtdGN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NzM3NzksImV4cCI6MjA5MjM0OTc3OX0.kvsO6GRZQoEvj7olJxJgxcgFJJpchwu75rj1vs401YU';

  // Table names
  static const String tableUsers = 'users';
  static const String tableStudents = 'students';
  static const String tableFaculty = 'faculty';
  static const String tableSessions = 'sessions';
  static const String tableAttendance = 'attendance_records';
  static const String tableSubjects = 'subjects';
}
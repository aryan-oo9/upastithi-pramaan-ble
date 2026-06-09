// lib/app/routes.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/features/admin/add_faculty_screen.dart';
import 'package:upastithi_pramaan/features/admin/admin_dashboard.dart';
import 'package:upastithi_pramaan/features/admin/manage_subjects_screen.dart';
import 'package:upastithi_pramaan/features/admin/view_faculty_screen.dart';
import 'package:upastithi_pramaan/features/admin/view_students_screen.dart';
import 'package:upastithi_pramaan/features/auth/login_screen.dart';
import 'package:upastithi_pramaan/features/auth/register_screen.dart';
import 'package:upastithi_pramaan/features/student/student_dashboard.dart';
import 'package:upastithi_pramaan/features/teacher/teacher_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeLogin,
    routes: [
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeTeacherDashboard,
        name: 'teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: AppConstants.routeStudentDashboard,
        name: 'student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Admin routes ─────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        name: 'admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: AppConstants.routeAdminAddFaculty,
        name: 'admin-add-faculty',
        builder: (context, state) => const AddFacultyScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminSubjects,
        name: 'admin-subjects',
        builder: (context, state) => const ManageSubjectsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminStudents,
        name: 'admin-students',
        builder: (context, state) => const ViewStudentsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminFaculty,
        name: 'admin-faculty',
        builder: (context, state) => const ViewFacultyScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
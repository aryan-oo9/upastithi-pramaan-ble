// lib/features/admin/view_faculty_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';

final _facultyProvider = FutureProvider.autoDispose((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final res = await supabase
      .from('faculty')
      .select('id, emp_id, name, department, email, created_at')
      .order('name', ascending: true);
  return res as List<dynamic>;
});

class ViewFacultyScreen extends ConsumerWidget {
  const ViewFacultyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync = ref.watch(_facultyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty'),
        leading: BackButton(
            onPressed: () => context.go(AppConstants.routeAdminDashboard)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Faculty',
            onPressed: () => context.go(AppConstants.routeAdminAddFaculty),
          ),
        ],
      ),
      body: facultyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppTheme.error))),
        data: (faculty) {
          if (faculty.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: AppTheme.textDisabled),
                  SizedBox(height: 12),
                  Text('No faculty added yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${faculty.length} faculty members',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: faculty.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = faculty[i] as Map<String, dynamic>;
                    return _FacultyCard(faculty: f);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FacultyCard extends StatelessWidget {
  const _FacultyCard({required this.faculty});
  final Map<String, dynamic> faculty;

  @override
  Widget build(BuildContext context) {
    final name = faculty['name'] as String? ?? '—';
    final empId = faculty['emp_id'] as String? ?? '—';
    final department = faculty['department'] as String? ?? '—';
    final email = faculty['email'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(empId,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(department,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
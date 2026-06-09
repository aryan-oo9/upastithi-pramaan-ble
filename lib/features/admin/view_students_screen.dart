// lib/features/admin/view_students_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';

final _studentsProvider = FutureProvider.autoDispose((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final res = await supabase
      .from('students')
      .select('id, roll, name, division, semester, department, email, created_at')
      .order('created_at', ascending: false);
  return res as List<dynamic>;
});

class ViewStudentsScreen extends ConsumerWidget {
  const ViewStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_studentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        leading: BackButton(
            onPressed: () => context.go(AppConstants.routeAdminDashboard)),
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppTheme.error))),
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: AppTheme.textDisabled),
                  SizedBox(height: 12),
                  Text('No students registered yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${students.length} students',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = students[i] as Map<String, dynamic>;
                    return _StudentCard(student: s);
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

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? '—';
    final roll = student['roll'] as String? ?? '—';
    final division = student['division'] as String? ?? '—';
    final semester = student['semester'] as int?;
    final department = student['department'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
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
                Text(roll,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(label: department),
                    const SizedBox(width: 6),
                    if (semester != null) _Tag(label: 'Sem $semester'),
                    const SizedBox(width: 6),
                    _Tag(label: 'Div $division'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      );
}
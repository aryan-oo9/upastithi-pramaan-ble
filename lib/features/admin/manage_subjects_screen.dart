// lib/features/admin/manage_subjects_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';

// ── Data models ────────────────────────────────────────────────────────────

class _SubjectRow {
  _SubjectRow({
    required this.id,
    required this.code,
    required this.name,
    required this.semester,
    this.facultyId,
    this.facultyName,
  });
  final String id;
  final String code;
  final String name;
  final int semester;
  String? facultyId;
  String? facultyName;
}

class _FacultyOption {
  const _FacultyOption({required this.id, required this.name, required this.empId});
  final String id;
  final String name;
  final String empId;
}

// ── Providers ──────────────────────────────────────────────────────────────

final _subjectsProvider = FutureProvider.autoDispose<List<_SubjectRow>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final res = await supabase
      .from('subjects')
      .select('id, code, name, semester, faculty_id, faculty(name)')
      .order('semester', ascending: true)
      .order('code', ascending: true);

  return (res as List).map((e) {
    final map = e as Map<String, dynamic>;
    return _SubjectRow(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      semester: map['semester'] as int? ?? 0,
      facultyId: map['faculty_id'] as String?,
      facultyName: map['faculty'] != null
          ? (map['faculty'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }).toList();
});

final _facultyListProvider = FutureProvider.autoDispose<List<_FacultyOption>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final res = await supabase
      .from('faculty')
      .select('id, name, emp_id')
      .order('name', ascending: true);

  return (res as List).map((e) {
    final map = e as Map<String, dynamic>;
    return _FacultyOption(
      id: map['id'] as String,
      name: map['name'] as String,
      empId: map['emp_id'] as String,
    );
  }).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────

class ManageSubjectsScreen extends ConsumerStatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  ConsumerState<ManageSubjectsScreen> createState() =>
      _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends ConsumerState<ManageSubjectsScreen> {
  int _selectedSemester = 5;

  Future<void> _assignFaculty(
      _SubjectRow subject, _FacultyOption? faculty) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('subjects').update({
        'faculty_id': faculty?.id,
      }).eq('id', subject.id);

      ref.invalidate(_subjectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(faculty != null
                ? '${subject.code} assigned to ${faculty.name}'
                : '${subject.code} unassigned'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('assignFaculty error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showAssignDialog(
      _SubjectRow subject, List<_FacultyOption> facultyList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AssignFacultySheet(
        subject: subject,
        facultyList: facultyList,
        onAssign: (faculty) {
          Navigator.pop(ctx);
          _assignFaculty(subject, faculty);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(_subjectsProvider);
    final facultyAsync = ref.watch(_facultyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        leading: BackButton(
            onPressed: () => context.go(AppConstants.routeAdminDashboard)),
      ),
      body: Column(
        children: [
          // Semester filter
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sem = i + 1;
                final selected = sem == _selectedSemester;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSemester = sem),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.border),
                    ),
                    child: Center(
                      child: Text('Sem $sem',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Subject list
          Expanded(
            child: subjectsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style:
                          const TextStyle(color: AppTheme.error))),
              data: (subjects) {
                final filtered = subjects
                    .where((s) => s.semester == _selectedSemester)
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No subjects for this semester',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final subject = filtered[i];
                    return _SubjectCard(
                      subject: subject,
                      onTap: () => facultyAsync.whenData(
                          (fl) => _showAssignDialog(subject, fl)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subject card ───────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});
  final _SubjectRow subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAssigned = subject.facultyName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasAssigned ? AppTheme.accent.withValues(alpha: 0.4) : AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasAssigned
                    ? AppTheme.accent.withValues(alpha: 0.1)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasAssigned ? Icons.check_circle_outline : Icons.book_outlined,
                color: hasAssigned ? AppTheme.accent : AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subject.code,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  if (hasAssigned) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 11, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(subject.facultyName!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.edit_outlined,
                size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Assign faculty bottom sheet ────────────────────────────────────────────

class _AssignFacultySheet extends StatelessWidget {
  const _AssignFacultySheet({
    required this.subject,
    required this.facultyList,
    required this.onAssign,
  });
  final _SubjectRow subject;
  final List<_FacultyOption> facultyList;
  final void Function(_FacultyOption? faculty) onAssign;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign Faculty',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subject.name,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                // Unassign option
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_off_outlined,
                        color: AppTheme.error, size: 18),
                  ),
                  title: const Text('Remove Assignment',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.error,
                          fontWeight: FontWeight.w500)),
                  onTap: () => onAssign(null),
                ),
                const Divider(height: 1),
                ...facultyList.map((f) => ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(f.empId,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary)),
                        ),
                      ),
                      title: Text(f.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary)),
                      subtitle: Text(f.empId,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                      trailing: subject.facultyId == f.id
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.accent, size: 18)
                          : null,
                      onTap: () => onAssign(f),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
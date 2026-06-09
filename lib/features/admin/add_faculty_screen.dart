// lib/features/admin/add_faculty_screen.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class AddFacultyScreen extends ConsumerStatefulWidget {
  const AddFacultyScreen({super.key});

  @override
  ConsumerState<AddFacultyScreen> createState() => _AddFacultyScreenState();
}

class _AddFacultyScreenState extends ConsumerState<AddFacultyScreen> {
  final _nameCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _empIdCtrl.dispose();
    _emailCtrl.dispose();
    _departmentCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final empId = _empIdCtrl.text.trim().toUpperCase();
    final email = _emailCtrl.text.trim();
    final department = _departmentCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || empId.isEmpty || department.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = const Uuid().v4();
      final passwordHash = sha256.convert(utf8.encode(password)).toString();

      // Insert into users
      await supabase.from('users').insert({
        'id': userId,
        'role': 'faculty',
        'password_hash': passwordHash,
        'name': name,
      });

      // Insert into faculty
      await supabase.from('faculty').insert({
        'id': userId,
        'emp_id': empId,
        'name': name,
        'email': email.isEmpty ? null : email,
        'department': department,
      });

      AppLogger.i('Faculty added: $empId');

      // Clear form
      _nameCtrl.clear();
      _empIdCtrl.clear();
      _emailCtrl.clear();
      _departmentCtrl.clear();
      _passwordCtrl.clear();
      _confirmCtrl.clear();

      setState(() => _successMessage = 'Faculty "$name" added successfully!');
    } catch (e) {
      AppLogger.e('AddFaculty error', e);
      setState(() => _errorMessage = 'Failed to add faculty: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Faculty'),
        leading: BackButton(
            onPressed: () => context.go(AppConstants.routeAdminDashboard)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Faculty Details',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Register a new faculty member',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),

            _FieldLabel('Full Name *'),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Prof. John Doe',
                prefixIcon: Icon(Icons.person_outline,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Employee ID *'),
            TextField(
              controller: _empIdCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. JD or FAC002',
                prefixIcon: Icon(Icons.badge_outlined,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Email'),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'e.g. jdoe@college.edu',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Department *'),
            TextField(
              controller: _departmentCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Computer Engineering',
                prefixIcon: Icon(Icons.school_outlined,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Password *'),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Min 6 characters',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: AppTheme.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Confirm Password *'),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: AppTheme.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _MessageBox(message: _errorMessage!, isError: true),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              _MessageBox(message: _successMessage!, isError: false),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add_outlined, size: 18),
              label: Text(_isLoading ? 'Adding…' : 'Add Faculty'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.error : AppTheme.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
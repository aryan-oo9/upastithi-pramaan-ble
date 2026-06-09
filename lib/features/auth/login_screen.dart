// lib/features/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/data/models/app_user.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole _selectedRole = UserRole.student;
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Only require id for student/faculty
  Future<void> _login() async {
    final id = _idController.text.trim();
    final password = _passwordController.text;

    if ((_selectedRole != UserRole.admin && id.isEmpty) || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      AppUser user;

      if (_selectedRole == UserRole.student) {
        user = await authService.loginStudent(
          rollNumber: id,
          password: password,
        );
      } else if (_selectedRole == UserRole.faculty) {
        user = await authService.loginFaculty(
          empId: id,
          password: password,
        );
      } else {
        user = await authService.loginAdmin(
          password: password,
        );
      }

      ref.read(currentUserProvider.notifier).state = user;

      if (mounted) {
        if (user.isStudent) {
          context.go(AppConstants.routeStudentDashboard);
        } else if (user.isFaculty) {
          context.go(AppConstants.routeTeacherDashboard);
        } else {
          context.go(AppConstants.routeAdminDashboard);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fingerprint,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                'Upastithi\nPramaan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Secure · Offline · Proxy-free attendance',
                style:
                    TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 40),

              // Role toggle
              const Text('I am a',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _RoleTab(
                      label: 'Student',
                      icon: Icons.person_outline,
                      selected: _selectedRole == UserRole.student,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.student),
                    ),
                    _RoleTab(
                      label: 'Teacher',
                      icon: Icons.school_outlined,
                      selected: _selectedRole == UserRole.faculty,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.faculty),
                    ),
                    _RoleTab(
                      label: 'Admin',
                      icon: Icons.admin_panel_settings_outlined,
                      selected: _selectedRole == UserRole.admin,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.admin),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ID field — hidden for admin
              if (_selectedRole != UserRole.admin) ...[
                Text(
                  _selectedRole == UserRole.student
                      ? 'Roll Number'
                      : 'Employee ID',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _idController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: _selectedRole == UserRole.student
                        ? 'e.g. CE001'
                        : 'e.g. FAC001',
                    prefixIcon: Icon(
                      _selectedRole == UserRole.student
                          ? Icons.badge_outlined
                          : Icons.work_outline,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 16),
                      SizedBox(width: 8),
                      Text('Admin login requires only password',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.warning)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Password field
              const Text('Password',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: AppTheme.error, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 24),

              // Login button
              FilledButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In'),
              ),

              // Register link — only for students
              if (_selectedRole == UserRole.student)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New student?',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                    TextButton(
                      onPressed: () =>
                          context.go(AppConstants.routeRegister),
                      child: const Text('Register here',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.textSecondary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
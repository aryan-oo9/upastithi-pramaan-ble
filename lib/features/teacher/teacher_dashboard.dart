// lib/features/teacher/teacher_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/data/models/session_model.dart';
import 'package:upastithi_pramaan/features/teacher/session_code_widget.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';
import 'package:upastithi_pramaan/services/ble_service.dart';
import 'package:upastithi_pramaan/services/session_service.dart';
import 'package:upastithi_pramaan/core/utils/session_code_generator.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  SessionModel? _session;
  bool _isStarting = false;
  Timer? _codeSyncTimer;
  int _presentCount = 0;

  @override
  void dispose() {
    _codeSyncTimer?.cancel();
    ref.read(bleServiceProvider.notifier).stopSession();
    if (_session != null) {
      ref.read(sessionServiceProvider).endSession(_session!.id);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showError('Not logged in');
      return;
    }

    setState(() => _isStarting = true);

    try {
      final currentCode = ref.read(sessionCodeProvider);

      // 1. Create session in Supabase
      // For demo use first subject — in real app show subject picker
      final session = await ref.read(sessionServiceProvider).createSession(
            facultyId: user.id,
            subjectId: 'cccccccc-cccc-cccc-cccc-cccccccccccc', // TODO: subject picker in Phase 4
            initialCode: currentCode,
          );

      setState(() => _session = session);

      // 2. Start BLE advertising
      await ref.read(bleServiceProvider.notifier).startSession(
            teacherName: user.name,
            roomCode: 'R101',
          );

      // 3. Sync code to Supabase every time it rotates
      _startCodeSyncTimer();

      AppLogger.i('Session started: ${session.id}');
    } catch (e) {
      _showError('Failed to start session: $e');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _startCodeSyncTimer() {
    _codeSyncTimer?.cancel();
    // Check every 5s if code changed and push to Supabase
    _codeSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_session == null) return;
      final currentCode = ref.read(sessionCodeProvider);
      await ref.read(sessionServiceProvider).updateSessionCode(
            sessionId: _session!.id,
            newCode: currentCode,
            expiresAt: DateTime.now().add(const Duration(seconds: 50)),
          );
    });
  }

  Future<void> _stopSession() async {
    _codeSyncTimer?.cancel();
    await ref.read(bleServiceProvider.notifier).stopSession();
    if (_session != null) {
      await ref.read(sessionServiceProvider).endSession(_session!.id);
    }
    setState(() => _session = null);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bleState = ref.watch(bleServiceProvider);
    final isAdvertising = bleState == BleServiceState.advertising;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        leading: BackButton(onPressed: () {
          _stopSession();
          ref.read(currentUserProvider.notifier).state = null;
          context.go(AppConstants.routeLogin);
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(Icons.bluetooth,
                  size: 14,
                  color: isAdvertising
                      ? AppTheme.accent
                      : AppTheme.textDisabled),
              label: Text(isAdvertising ? 'Broadcasting' : 'Idle'),
              backgroundColor: isAdvertising
                  ? AppTheme.accent.withValues(alpha: 0.1)
                  : AppTheme.surfaceVariant,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isAdvertising
                    ? AppTheme.accent
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Session Code',
              child: const Center(child: SessionCodeWidget()),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'BLE Session',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Teacher',
                    value: user?.name ?? 'Demo Teacher',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.room,
                    label: 'Room',
                    value: 'Room 101',
                  ),
                  if (_session != null) ...[
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.tag,
                      label: 'Session ID',
                      value: '${_session!.id.substring(0, 8)}…',
                    ),
                    if (_session!.subjectName != null) ...[
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.book_outlined,
                        label: 'Subject',
                        value: _session!.subjectName!,
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isStarting || isAdvertising ? null : _startSession,
                      icon: _isStarting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bluetooth),
                      label: Text(isAdvertising
                          ? 'Broadcasting…'
                          : _isStarting
                              ? 'Starting…'
                              : 'Start BLE Session'),
                    ),
                  ),
                  if (isAdvertising) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _stopSession,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Session'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Attendance',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                      label: 'Present',
                      value: '$_presentCount',
                      color: AppTheme.accent),
                  _StatBox(
                      label: 'Total',
                      value: '—',
                      color: AppTheme.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Card(
            child:
                Padding(padding: const EdgeInsets.all(20), child: child)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }
}
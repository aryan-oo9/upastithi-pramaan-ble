// lib/features/student/student_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/data/models/session_model.dart';
import 'package:upastithi_pramaan/features/student/code_entry_widget.dart';
import 'package:upastithi_pramaan/features/student/proximity_indicator.dart';
import 'package:upastithi_pramaan/platform/ble_channel.dart';
import 'package:upastithi_pramaan/services/auth_service.dart';
import 'package:upastithi_pramaan/services/ble_service.dart';
import 'package:upastithi_pramaan/services/session_service.dart';
import 'package:upastithi_pramaan/features/student/face_verification_widget.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  bool _codeVerified = false;
  bool _faceVerified = false;
  bool _attendanceSubmitted = false;
  BleScanResult? _selectedBleSession;
  SessionModel? _selectedSession;
  List<SessionModel> _activeSessions = [];
  bool _loadingSessions = false;
  CodeVerifyResult? _codeResult;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
  }

  @override
  void dispose() {
    ref.read(bleServiceProvider.notifier).stopScan();
    super.dispose();
  }

  Future<void> _loadActiveSessions() async {
    setState(() => _loadingSessions = true);
    final sessions =
        await ref.read(sessionServiceProvider).getActiveSessions();
    if (mounted) {
      setState(() {
        _activeSessions = sessions;
        _loadingSessions = false;
      });
    }
  }

  Future<void> _onCodeSubmit(String code) async {
    if (_selectedSession == null) {
      _showSnack('Please select a session first', isError: true);
      return;
    }

    final result = await ref.read(sessionServiceProvider).verifySessionCode(
          sessionId: _selectedSession!.id,
          enteredCode: code,
        );

    setState(() => _codeResult = result);

    switch (result) {
      case CodeVerifyResult.valid:
        setState(() => _codeVerified = true);
        _showSnack('Code verified ✓', isError: false);
        _trySubmitAttendance();
      case CodeVerifyResult.expired:
        _showSnack('Code expired — enter the latest code', isError: true);
      case CodeVerifyResult.invalid:
        _showSnack('Invalid code', isError: true);
      case CodeVerifyResult.sessionEnded:
        _showSnack('Session has ended', isError: true);
      case CodeVerifyResult.error:
        _showSnack('Network error — check connection', isError: true);
    }
  }

  Future<void> _trySubmitAttendance() async {
    if (!_codeVerified || !_faceVerified) return;
    if (_selectedSession == null) return;
    if (_attendanceSubmitted) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final bleVerified = _selectedBleSession?.isNear ?? false;

    try {
      await ref.read(sessionServiceProvider).submitAttendance(
            sessionId: _selectedSession!.id,
            studentId: user.id,
            bleVerified: bleVerified,
            bleRssi: _selectedBleSession?.rssi ?? -100,
            faceVerified: _faceVerified,
            codeVerified: _codeVerified,
          );
      setState(() => _attendanceSubmitted = true);
      _showSnack('Attendance recorded! ✓', isError: false);
    } catch (e) {
      _showSnack('Failed to submit attendance: $e', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.accent,
    ));
  }

  ProximityState _proximityState() {
    if (_selectedBleSession == null) {
      final bleState = ref.watch(bleServiceProvider);
      return bleState == BleServiceState.scanning
          ? ProximityState.scanning
          : ProximityState.unknown;
    }
    return _selectedBleSession!.isNear
        ? ProximityState.near
        : ProximityState.far;
  }

  @override
  Widget build(BuildContext context) {
    final nearbyTeachers = ref.watch(nearbyTeachersProvider);
    final user = ref.watch(currentUserProvider);
    final proxState = _proximityState();
    final allVerified = _codeVerified &&
        _faceVerified &&
        proxState == ProximityState.near;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        leading: BackButton(onPressed: () {
          ref.read(bleServiceProvider.notifier).stopScan();
          ref.read(currentUserProvider.notifier).state = null;
          context.go(AppConstants.routeLogin);
        }),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(user.rollNumber ?? user.name,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            if (_attendanceSubmitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.4)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: AppTheme.accent),
                  SizedBox(width: 10),
                  Text('Attendance Recorded!',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent)),
                ]),
              ),

            // ── Active Sessions ───────────────────────────────────────────
            _SectionLabel('Select Session'),
            if (_loadingSessions)
              const Center(child: CircularProgressIndicator())
            else if (_activeSessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('No active sessions found',
                          style:
                              TextStyle(color: AppTheme.textSecondary))),
                  TextButton(
                      onPressed: _loadActiveSessions,
                      child: const Text('Refresh')),
                ]),
              )
            else
              ..._activeSessions.map((s) => _ActiveSessionTile(
                    session: s,
                    isSelected: _selectedSession?.id == s.id,
                    onTap: () => setState(() => _selectedSession = s),
                  )),
            const SizedBox(height: 20),

            // ── Step 1: BLE ───────────────────────────────────────────────
            _SectionLabel('Step 1 · BLE Proximity'),
            ProximityIndicator(
              state: proxState,
              rssi: _selectedBleSession?.rssi,
              teacherName: _selectedBleSession?.teacherName,
            ),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(bleServiceProvider.notifier).startScan(),
                icon: const Icon(Icons.bluetooth_searching, size: 18),
                label: const Text('Scan'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(bleServiceProvider.notifier).stopScan(),
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Stop'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppTheme.error),
              ),
            ]),
            if (nearbyTeachers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Detected beacons:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              ...nearbyTeachers.values.map((r) => _BleTile(
                    result: r,
                    isSelected: _selectedBleSession?.mac == r.mac,
                    onTap: () =>
                        setState(() => _selectedBleSession = r),
                  )),
            ],
            const SizedBox(height: 20),

            // ── Step 2: Code ──────────────────────────────────────────────
            _SectionLabel('Step 2 · Session Code'),
            CodeEntryWidget(onSubmit: _onCodeSubmit),
            if (_codeVerified)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(children: [
                  Icon(Icons.check_circle,
                      color: AppTheme.accent, size: 16),
                  SizedBox(width: 6),
                  Text('Code verified',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(height: 20),

            // ── Step 3: Face ──────────────────────────────────────────────
            _SectionLabel('Step 3 · Face Verification'),
            if (_faceVerified)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                ),
                child: const Row(children: [
                  Icon(Icons.verified_user, color: AppTheme.accent, size: 18),
                  SizedBox(width: 8),
                  Text('Identity Verified',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600)),
                ]),
              )
            else
              FaceVerificationWidget(
                onVerified: () {
                  setState(() => _faceVerified = true);
                  _trySubmitAttendance();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionTile extends StatelessWidget {
  const _ActiveSessionTile({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });
  final SessionModel session;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(children: [
          Icon(Icons.book_outlined,
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subjectName ?? 'Unknown Subject',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary),
                ),
                Text(session.subjectCode ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle,
                color: AppTheme.primary, size: 18),
        ]),
      ),
    );
  }
}

class _BleTile extends StatelessWidget {
  const _BleTile({
    required this.result,
    required this.isSelected,
    required this.onTap,
  });
  final BleScanResult result;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(children: [
          Icon(Icons.bluetooth,
              size: 18,
              color:
                  result.isNear ? AppTheme.accent : AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.teacherName.isNotEmpty
                    ? result.teacherName
                    : result.mac),
                Text(result.roomCode,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text('${result.rssi} dBm',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
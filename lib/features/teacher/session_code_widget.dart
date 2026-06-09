// lib/features/teacher/session_code_widget.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';
import 'package:upastithi_pramaan/core/utils/session_code_generator.dart';

/// Displays the current 6-digit rotating session code with a countdown ring.
class SessionCodeWidget extends ConsumerStatefulWidget {
  const SessionCodeWidget({super.key});

  @override
  ConsumerState<SessionCodeWidget> createState() => _SessionCodeWidgetState();
}

class _SessionCodeWidgetState extends ConsumerState<SessionCodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _totalSeconds;
  String _lastCode = '';

  @override
  void initState() {
    super.initState();
    _totalSeconds = _randomInterval();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    )..forward();
  }

  int _randomInterval() {
    final rng = Random();
    return AppConstants.sessionCodeRefreshMinSeconds +
        rng.nextInt(AppConstants.sessionCodeRefreshMaxSeconds -
            AppConstants.sessionCodeRefreshMinSeconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(sessionCodeProvider);

    // Reset animation whenever code rotates
    if (code != _lastCode) {
      _lastCode = code;
      _totalSeconds = _randomInterval();
      _controller
        ..duration = Duration(seconds: _totalSeconds)
        ..forward(from: 0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final remaining =
            (_totalSeconds * (1 - _controller.value)).ceil();
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1 - _controller.value,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 6,
                      ),
                    ),
                    Text(
                      '${remaining}s',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Rotating session code',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        );
      },
    );
  }
}
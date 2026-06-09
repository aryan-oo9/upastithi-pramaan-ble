// lib/core/utils/session_code_generator.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upastithi_pramaan/core/constants/app_constants.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';

class SessionCodeNotifier extends Notifier<String> {
  Timer? _timer;
  final _rng = Random.secure();

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    _scheduleNext();
    return _generate();
  }

  String _generate() {
    final code = (_rng.nextInt(900000) + 100000).toString();
    AppLogger.d('SessionCode rotated → $code');
    return code;
  }

  void _scheduleNext() {
    _timer?.cancel();
    final interval = AppConstants.sessionCodeRefreshMinSeconds +
        _rng.nextInt(
          AppConstants.sessionCodeRefreshMaxSeconds -
              AppConstants.sessionCodeRefreshMinSeconds,
        );
    _timer = Timer(Duration(seconds: interval), () {
      state = _generate();
      _scheduleNext();
    });
  }
}

final sessionCodeProvider = NotifierProvider<SessionCodeNotifier, String>(
  SessionCodeNotifier.new,
);
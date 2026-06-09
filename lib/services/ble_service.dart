// lib/services/ble_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';
import 'package:upastithi_pramaan/platform/ble_channel.dart';

enum BleServiceState { idle, advertising, scanning, error }

class BleServiceNotifier extends Notifier<BleServiceState> {
  @override
  BleServiceState build() => BleServiceState.idle;

  // ── Teacher ────────────────────────────────────────────────────────────────

  Future<String> startSession({
    required String teacherName,
    required String roomCode,
  }) async {
    final sessionUuid = const Uuid().v4();
    try {
      await BleChannel.startAdvertising(
        sessionUuid: sessionUuid,
        teacherName: teacherName,
        roomCode: roomCode,
      );
      state = BleServiceState.advertising;
      AppLogger.i('Session started: $sessionUuid');
    } catch (e) {
      state = BleServiceState.error;
      AppLogger.e('startSession failed', e);
      rethrow;
    }
    return sessionUuid;
  }

  Future<void> stopSession() async {
    await BleChannel.stopAdvertising();
    state = BleServiceState.idle;
  }

  // ── Student ────────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    try {
      await BleChannel.startScan();
      state = BleServiceState.scanning;
    } catch (e) {
      state = BleServiceState.error;
      AppLogger.e('startScan failed', e);
      rethrow;
    }
  }

  Future<void> stopScan() async {
    await BleChannel.stopScan();
    state = BleServiceState.idle;
  }
}

final bleServiceProvider =
    NotifierProvider<BleServiceNotifier, BleServiceState>(
  BleServiceNotifier.new,
);
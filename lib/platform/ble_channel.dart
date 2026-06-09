// lib/platform/ble_channel.dart

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upastithi_pramaan/core/constants/ble_constants.dart';
import 'package:upastithi_pramaan/core/utils/app_logger.dart';

/// Parsed scan result from a nearby teacher BLE advertisement.
class BleScanResult {
  const BleScanResult({
    required this.mac,
    required this.rssi,
    required this.isNear,
    required this.sessionUuid,
    required this.teacherName,
    required this.roomCode,
  });

  final String mac;
  final int rssi;
  final bool isNear;
  final String sessionUuid;
  final String teacherName;
  final String roomCode;

  factory BleScanResult.fromMap(Map<Object?, Object?> map) {
    return BleScanResult(
      mac: map['mac'] as String? ?? '',
      rssi: map['rssi'] as int? ?? -100,
      isNear: map['isNear'] as bool? ?? false,
      sessionUuid: map['sessionUuid'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      roomCode: map['roomCode'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'BleScanResult(mac=$mac rssi=$rssi isNear=$isNear teacher=$teacherName)';
}

/// Low-level wrapper around the native BLE platform channel.
class BleChannel {
  BleChannel._();

  static const _method = MethodChannel(BleConstants.bleMethodChannel);
  static const _eventChannel = EventChannel(BleConstants.bleScanEventChannel);

  static StreamSubscription<BleScanResult>? _scanSubscription;

  // ── Advertising ────────────────────────────────────────────────────────────

  static Future<void> startAdvertising({
    required String sessionUuid,
    required String teacherName,
    required String roomCode,
  }) async {
    try {
      await _method.invokeMethod(BleConstants.bleAdvertiseMethod, {
        'sessionUuid': sessionUuid,
        'teacherName': teacherName,
        'roomCode': roomCode,
      });
      AppLogger.i('BLE advertising started');
    } on PlatformException catch (e) {
      AppLogger.e('startAdvertising failed', e);
      rethrow;
    }
  }

  static Future<void> stopAdvertising() async {
    try {
      await _method.invokeMethod(BleConstants.bleStopAdvertiseMethod);
      AppLogger.i('BLE advertising stopped');
    } on PlatformException catch (e) {
      AppLogger.e('stopAdvertising failed', e);
    }
  }

  // ── Scanning ───────────────────────────────────────────────────────────────

  static Stream<BleScanResult> get scanStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => BleScanResult.fromMap(event as Map<Object?, Object?>));
  }

  static Future<void> startScan() async {
    try {
      await _method.invokeMethod(BleConstants.bleScanMethod);
      AppLogger.i('BLE scan started');
    } on PlatformException catch (e) {
      AppLogger.e('startScan failed', e);
      rethrow;
    }
  }

  static Future<void> stopScan() async {
    try {
      await _method.invokeMethod(BleConstants.bleStopScanMethod);
      AppLogger.i('BLE scan stopped');
    } on PlatformException catch (e) {
      AppLogger.e('stopScan failed', e);
    }
  }
}

// ── Riverpod providers ─────────────────────────────────────────────────────

/// Streams live BLE scan results.
final bleScanStreamProvider = StreamProvider<BleScanResult>((ref) {
  ref.onDispose(BleChannel.stopScan);
  return BleChannel.scanStream;
});

/// Deduplicated map of MAC → latest scan result (all nearby teachers).
final nearbyTeachersProvider =
    StateNotifierProvider<NearbyTeachersNotifier, Map<String, BleScanResult>>(
  NearbyTeachersNotifier.new,
);

class NearbyTeachersNotifier
    extends StateNotifier<Map<String, BleScanResult>> {
  NearbyTeachersNotifier(this.ref) : super({}) {
    _sub = ref.listen(bleScanStreamProvider, (_, next) {
      next.whenData((result) {
        state = {...state, result.mac: result};
      });
    });
  }

  final Ref ref;
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
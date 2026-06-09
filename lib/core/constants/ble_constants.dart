// lib/core/constants/ble_constants.dart

class BleConstants {
  BleConstants._();

  // Service UUID for Upastithi Pramaan BLE advertisements
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  // Manufacturer ID used in advertisement payload
  static const int manufacturerId = 0x004C; // arbitrary; override as needed

  // Advertisement payload structure (packed into manufacturer data bytes)
  // Byte 0-35 : Session UUID (36 chars ASCII, truncated/padded)
  // Byte 36-51: Teacher name (16 chars ASCII, truncated/padded)
  // Byte 52-59: Room code  (8 chars ASCII, truncated/padded)
  static const int payloadSessionUuidOffset = 0;
  static const int payloadSessionUuidLength = 36;
  static const int payloadTeacherNameOffset = 36;
  static const int payloadTeacherNameLength = 16;
  static const int payloadRoomCodeOffset = 52;
  static const int payloadRoomCodeLength = 8;
  static const int totalPayloadLength = 60;

  // BLE scan settings
  static const Duration scanWindow = Duration(seconds: 10);
  static const int rssiWindowSize = 7;
  static const int rssiThresholdDbm = -65;

  // Platform channel names
  static const String bleMethodChannel = 'com.upastithi/ble';
  static const String bleAdvertiseMethod = 'startAdvertising';
  static const String bleStopAdvertiseMethod = 'stopAdvertising';
  static const String bleScanMethod = 'startScan';
  static const String bleStopScanMethod = 'stopScan';

  // Event channel for scan results streamed from Kotlin
  static const String bleScanEventChannel = 'com.upastithi/ble_scan_events';
}
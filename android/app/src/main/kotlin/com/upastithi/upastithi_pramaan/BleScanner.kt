// BleScanner.kt
package com.upastithi.upastithi_pramaan

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.util.Log

class BleScanner(private val bluetoothAdapter: BluetoothAdapter) {

    private val TAG = "BleScanner"
    private var scanner: BluetoothLeScanner? = null
    private var scanCallback: ScanCallback? = null
    private val rssiWindows = mutableMapOf<String, ArrayDeque<Int>>()
    private val WINDOW_SIZE = 7
    private val RSSI_THRESHOLD = -65

    fun start(onResult: (Map<String, Any>) -> Unit, onError: (String) -> Unit) {
        try {
            if (!bluetoothAdapter.isEnabled) {
                onError("Bluetooth is not enabled")
                return
            }

            if (scanCallback != null) return

            scanner = bluetoothAdapter.bluetoothLeScanner
            if (scanner == null) {
                onError("BLE scanner not available")
                return
            }

            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .setReportDelay(0)
                .build()

            scanCallback = object : ScanCallback() {
                override fun onScanResult(callbackType: Int, result: ScanResult) {
                    val record = result.scanRecord ?: return

                    // Filter by manufacturer ID presence — more reliable than UUID filter
                    // on Android 12+ non-connectable adverts where UUID can be in scan
                    // response only (not visible to hardware filters).
                    // Manufacturer ID 0x05AC is our app-specific marker — low collision risk.
                    val mfr = record.getManufacturerSpecificData(BleAdvertiser.MANUFACTURER_ID)
                    if (mfr == null || mfr.size < 3) return

                    try {
                        processScanResult(result, onResult)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error processing scan result", e)
                    }
                }

                override fun onBatchScanResults(results: MutableList<ScanResult>) {
                    results.forEach { result ->
                        val record = result.scanRecord ?: return@forEach
                        val mfr = record.getManufacturerSpecificData(BleAdvertiser.MANUFACTURER_ID)
                        if (mfr == null || mfr.size < 3) return@forEach
                        try {
                            processScanResult(result, onResult)
                        } catch (e: Exception) {
                            Log.e(TAG, "Batch scan error", e)
                        }
                    }
                }

                override fun onScanFailed(errorCode: Int) {
                    val reason = when (errorCode) {
                        SCAN_FAILED_ALREADY_STARTED                 -> "Already started"
                        SCAN_FAILED_APPLICATION_REGISTRATION_FAILED -> "App registration failed"
                        SCAN_FAILED_FEATURE_UNSUPPORTED             -> "Feature unsupported"
                        SCAN_FAILED_INTERNAL_ERROR                  -> "Internal error"
                        else -> "Unknown error $errorCode"
                    }
                    Log.e(TAG, "Scan failed: $reason")
                    onError("BLE scan failed: $reason")
                }
            }

            // No hardware filters — fully software filtered above.
            // This is intentional: fixes Android 16 scan-filter bugs where
            // UUID-based hardware filters silently drop scan response packets.
            scanner?.startScan(emptyList(), settings, scanCallback)
            Log.d(TAG, "✅ BLE scan started (filterless, software UUID check)")

        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException in BLE scan", e)
            onError("Permission denied: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception starting BLE scan", e)
            onError("BLE error: ${e.message}")
        }
    }

    fun stop() {
        try {
            scanCallback?.let { scanner?.stopScan(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping scanner", e)
        } finally {
            scanCallback = null
            rssiWindows.clear()
        }
    }

    private fun processScanResult(
        result: ScanResult,
        onResult: (Map<String, Any>) -> Unit
    ) {
        val mac = result.device.address
        val rssi = result.rssi

        // RSSI sliding window average
        val window = rssiWindows.getOrPut(mac) { ArrayDeque() }
        window.addLast(rssi)
        if (window.size > WINDOW_SIZE) window.removeFirst()
        val avgRssi = window.average().toInt()
        val isNear = avgRssi >= RSSI_THRESHOLD

        // Parse 3-byte session prefix from manufacturer data
        // [0x29, 0x37, 0x90] → "293790" (matches first 6 chars of session UUID hex)
        val manufacturerData = result.scanRecord
            ?.getManufacturerSpecificData(BleAdvertiser.MANUFACTURER_ID)

        val sessionPrefix = if (manufacturerData != null && manufacturerData.size >= 3) {
            manufacturerData.take(3).joinToString("") { "%02x".format(it) }
        } else {
            ""
        }

        // Teacher name and room code are not in payload in this revision.
        // Student side matches session via Supabase active sessions list,
        // using sessionPrefix to cross-reference beacon_id stored in sessions table.
        // This keeps the BLE payload minimal and avoids scan response budget issues.
        val teacherName = ""
        val roomCode = ""

        Log.d(TAG, "📡 mac=$mac rssi=$rssi avg=$avgRssi near=$isNear prefix=$sessionPrefix")

        onResult(mapOf(
            "mac"         to mac,
            "rssi"        to avgRssi,
            "isNear"      to isNear,
            "sessionUuid" to sessionPrefix,
            "teacherName" to teacherName,
            "roomCode"    to roomCode,
        ))
    }
}
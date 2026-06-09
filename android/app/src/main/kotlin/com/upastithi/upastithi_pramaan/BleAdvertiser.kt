// BleAdvertiser.kt
package com.upastithi.upastithi_pramaan

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.os.ParcelUuid
import android.util.Log
import java.util.UUID

class BleAdvertiser(private val bluetoothAdapter: BluetoothAdapter) {

    private val TAG = "BleAdvertiser"
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    fun start(
        sessionUuid: String,
        teacherName: String,
        roomCode: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            if (!bluetoothAdapter.isEnabled) {
                onError("Bluetooth is not enabled — please turn on Bluetooth")
                return
            }

            if (!bluetoothAdapter.isMultipleAdvertisementSupported) {
                onError("Device does not support BLE advertising")
                return
            }

            if (advertiseCallback != null) stop()

            advertiser = bluetoothAdapter.bluetoothLeAdvertiser
            if (advertiser == null) {
                onError("Could not get BLE advertiser")
                return
            }

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setConnectable(false)
                .setTimeout(0)
                .build()

            // BLE 31-byte budget for primary advert:
            // Flags:        3 bytes (auto-added by Android)
            // Manufacturer: 7 bytes (2 header + 2 company ID + 3 data)
            // Total:       10 bytes ✅ well within 31
            //
            // Scan response carries the 128-bit UUID (18 bytes) — no budget conflict

            // 3-byte payload = first 3 bytes of session UUID parsed from hex
            // e.g. "293790fd-..." → [0x29, 0x37, 0x90]
            val sessionBytes = sessionUuid.replace("-", "")
                .chunked(2)
                .take(3)
                .map { it.toInt(16).toByte() }
                .toByteArray()

            // Primary packet: only manufacturer data (no UUID here — it was being
            // silently dropped/overridden by Android on non-connectable adverts)
            val advertiseData = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .setIncludeTxPowerLevel(false)
                .addManufacturerData(MANUFACTURER_ID, sessionBytes)
                .build()

            // Scan response: UUID goes here — this is where Android reliably includes it
            // Budget: 18 bytes UUID + 2 header = 20 bytes, well within 31
            val scanResponse = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .setIncludeTxPowerLevel(false)
                .addServiceUuid(ParcelUuid(UUID.fromString(SERVICE_UUID)))
                .build()

            advertiseCallback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    Log.d(TAG, "✅ BLE advertising started successfully")
                    onSuccess()
                }
                override fun onStartFailure(errorCode: Int) {
                    val reason = when (errorCode) {
                        ADVERTISE_FAILED_ALREADY_STARTED      -> "Already started"
                        ADVERTISE_FAILED_DATA_TOO_LARGE       -> "Data too large"
                        ADVERTISE_FAILED_FEATURE_UNSUPPORTED  -> "Feature unsupported"
                        ADVERTISE_FAILED_INTERNAL_ERROR       -> "Internal error"
                        ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "Too many advertisers"
                        else -> "Unknown error $errorCode"
                    }
                    Log.e(TAG, "❌ Advertise failed: $reason (code=$errorCode)")
                    onError(reason)
                }
            }

            advertiser?.startAdvertising(settings, advertiseData, scanResponse, advertiseCallback)

        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException", e)
            onError("Permission denied: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception", e)
            onError("BLE error: ${e.message}")
        }
    }

    fun stop() {
        try {
            advertiseCallback?.let { advertiser?.stopAdvertising(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Stop error", e)
        } finally {
            advertiseCallback = null
            advertiser = null
        }
    }

    companion object {
        const val SERVICE_UUID    = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
        const val MANUFACTURER_ID = 0x05AC
    }
}
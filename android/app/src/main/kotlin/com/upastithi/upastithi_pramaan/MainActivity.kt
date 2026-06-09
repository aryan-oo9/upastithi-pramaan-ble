// MainActivity.kt
package com.upastithi.upastithi_pramaan

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val TAG = "MainActivity"
    private val BLE_METHOD_CHANNEL = "com.upastithi/ble"
    private val BLE_EVENT_CHANNEL = "com.upastithi/ble_scan_events"
    private val BLE_PERMISSION_REQUEST_CODE = 1001

    private var bleAdvertiser: BleAdvertiser? = null
    private var bleScanner: BleScanner? = null
    private var scanEventSink: EventChannel.EventSink? = null

    // Pending call while waiting for permission grant
    private var pendingMethodResult: MethodChannel.Result? = null
    private var pendingMethodCall: String? = null
    private var pendingMethodArgs: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bluetoothAdapter = getBluetoothAdapter()

        // ── Method Channel ────────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BLE_METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "startAdvertising" -> {
                    if (bluetoothAdapter == null) {
                        result.error("BT_UNAVAILABLE", "Bluetooth not available", null)
                        return@setMethodCallHandler
                    }
                    if (!hasBlePermissions()) {
                        pendingMethodResult = result
                        pendingMethodCall = "startAdvertising"
                        pendingMethodArgs = mapOf(
                            "sessionUuid" to (call.argument("sessionUuid") ?: ""),
                            "teacherName" to (call.argument("teacherName") ?: ""),
                            "roomCode"    to (call.argument("roomCode") ?: ""),
                        )
                        requestBlePermissions()
                        return@setMethodCallHandler
                    }
                    doStartAdvertising(
                        bluetoothAdapter,
                        call.argument("sessionUuid") ?: "",
                        call.argument("teacherName") ?: "",
                        call.argument("roomCode") ?: "",
                        result
                    )
                }

                "stopAdvertising" -> {
                    bleAdvertiser?.stop()
                    bleAdvertiser = null
                    result.success(null)
                }

                "startScan" -> {
                    if (bluetoothAdapter == null) {
                        result.error("BT_UNAVAILABLE", "Bluetooth not available", null)
                        return@setMethodCallHandler
                    }
                    if (!hasBlePermissions()) {
                        pendingMethodResult = result
                        pendingMethodCall = "startScan"
                        requestBlePermissions()
                        return@setMethodCallHandler
                    }
                    doStartScan(bluetoothAdapter, result)
                }

                "stopScan" -> {
                    bleScanner?.stop()
                    bleScanner = null
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // ── Event Channel (scan results stream) ───────────────────────────
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BLE_EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "BLE EventChannel: onListen")
                scanEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "BLE EventChannel: onCancel")
                scanEventSink = null
            }
        })
    }

    // ── BLE actions ───────────────────────────────────────────────────────────

    private fun doStartAdvertising(
        adapter: BluetoothAdapter,
        sessionUuid: String,
        teacherName: String,
        roomCode: String,
        result: MethodChannel.Result
    ) {
        var replied = false

        bleAdvertiser = BleAdvertiser(adapter)
        bleAdvertiser?.start(
            sessionUuid = sessionUuid,
            teacherName = teacherName,
            roomCode = roomCode,
            onSuccess = {
                if (!replied) {
                    replied = true
                    runOnUiThread { result.success(null) }
                }
            },
            onError = { error ->
                if (!replied) {
                    replied = true
                    runOnUiThread { result.error("ADVERTISE_FAILED", error, null) }
                }
            }
        )
    }

    private fun doStartScan(
        adapter: BluetoothAdapter,
        result: MethodChannel.Result
    ) {
        bleScanner = BleScanner(adapter)
        bleScanner?.start(
            onResult = { data ->
                runOnUiThread { scanEventSink?.success(data) }
            },
            onError = { error ->
                runOnUiThread { scanEventSink?.error("SCAN_ERROR", error, null) }
            }
        )
        result.success(null)
    }

    // ── Permissions ───────────────────────────────────────────────────────────

    private fun hasBlePermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.BLUETOOTH_ADVERTISE
            ) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestBlePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_ADVERTISE,
                    Manifest.permission.BLUETOOTH_CONNECT,
                ),
                BLE_PERMISSION_REQUEST_CODE
            )
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                BLE_PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != BLE_PERMISSION_REQUEST_CODE) return

        val allGranted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        val result = pendingMethodResult
        val call   = pendingMethodCall
        val args   = pendingMethodArgs

        pendingMethodResult = null
        pendingMethodCall   = null
        pendingMethodArgs   = null

        if (!allGranted) {
            result?.error("PERMISSION_DENIED", "BLE permissions denied", null)
            return
        }

        val adapter = getBluetoothAdapter() ?: run {
            result?.error("BT_UNAVAILABLE", "Bluetooth not available", null)
            return
        }

        when (call) {
            "startAdvertising" -> result?.let {
                doStartAdvertising(
                    adapter,
                    args?.get("sessionUuid") ?: "",
                    args?.get("teacherName") ?: "",
                    args?.get("roomCode")    ?: "",
                    it
                )
            }
            "startScan" -> result?.let { doStartScan(adapter, it) }
        }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onDestroy() {
        bleAdvertiser?.stop()
        bleScanner?.stop()
        super.onDestroy()
    }

    private fun getBluetoothAdapter(): BluetoothAdapter? {
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return manager?.adapter
    }
}
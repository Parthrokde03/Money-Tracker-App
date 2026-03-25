package com.example.money_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val METHOD_CHANNEL = "com.example.money_tracker/sms"
    private val SMS_PERMISSION_CODE = 101

    private var pendingResult: MethodChannel.Result? = null
    private var pendingDays: Int = 30
    private var pendingSinceTimestamp: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInboxSms" -> {
                        val days = call.argument<Int>("days")
                        // sinceTimestamp takes priority over days
                        val sinceTs = call.argument<Number>("sinceTimestamp")?.toLong()
                        if (hasSmsPermission()) {
                            try {
                                result.success(readSmsInbox(days, sinceTs))
                            } catch (e: Exception) {
                                result.error("SMS_ERROR", e.message, null)
                            }
                        } else {
                            pendingResult = result
                            pendingDays = days ?: 30
                            pendingSinceTimestamp = sinceTs
                            requestSmsPermission()
                        }
                    }
                    "requestPermission" -> {
                        if (hasSmsPermission()) {
                            result.success(true)
                        } else {
                            pendingResult = result
                            requestSmsPermission()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestSmsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
            SMS_PERMISSION_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            val result = pendingResult
            pendingResult = null
            if (result != null) {
                if (granted) {
                    try {
                        result.success(readSmsInbox(pendingDays, pendingSinceTimestamp))
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.message, null)
                    }
                } else {
                    result.error("PERMISSION_DENIED", "SMS permission denied", null)
                }
            }
            pendingSinceTimestamp = null
        }
    }

    private fun readSmsInbox(days: Int?, sinceTimestamp: Long?): List<Map<String, Any?>> {
        val smsList = mutableListOf<Map<String, Any?>>()
        val uri = Uri.parse("content://sms/inbox")

        // If sinceTimestamp is provided, use it directly; otherwise fall back to days
        val cutoff = sinceTimestamp
            ?: (System.currentTimeMillis() - ((days ?: 30).toLong() * 24 * 60 * 60 * 1000))

        val cursor: Cursor? = contentResolver.query(
            uri, arrayOf("address", "body", "date"),
            "date > ?", arrayOf(cutoff.toString()), "date DESC"
        )
        cursor?.use {
            val addrIdx = it.getColumnIndex("address")
            val bodyIdx = it.getColumnIndex("body")
            val dateIdx = it.getColumnIndex("date")
            while (it.moveToNext()) {
                smsList.add(mapOf(
                    "address" to it.getString(addrIdx),
                    "body" to it.getString(bodyIdx),
                    "date" to it.getLong(dateIdx)
                ))
            }
        }
        return smsList
    }
}

package com.flywork.lingolabuddy

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

object MicrophonePermissionPlugin {
    const val CHANNEL_NAME = "com.flywork.lingolabuddy/microphone"
    private const val REQUEST_CODE = 9821

    private var pendingResult: MethodChannel.Result? = null
    private var activity: FlutterActivity? = null

    fun attach(flutterEngine: FlutterEngine, host: FlutterActivity) {
        activity = host
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request" -> requestPermission(result)
                    "isGranted" -> result.success(isGranted())
                    "prepare" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }

    fun handlePermissionResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val granted =
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingResult?.success(granted)
        pendingResult = null
        return true
    }

    private fun isGranted(): Boolean {
        val host = activity ?: return false
        return ContextCompat.checkSelfPermission(
            host,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val host = activity
        if (host == null) {
            result.success(false)
            return
        }

        if (isGranted()) {
            result.success(true)
            return
        }

        if (pendingResult != null) {
            result.success(false)
            return
        }

        pendingResult = result
        ActivityCompat.requestPermissions(
            host,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQUEST_CODE,
        )
    }
}

package com.flywork.lingolabuddy

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object VoiceAudioSessionPlugin {
    const val CHANNEL_NAME = "lingolabuddy/voice_audio_session"

    private var proximityWakeLock: PowerManager.WakeLock? = null

    fun attach(flutterEngine: FlutterEngine, host: FlutterActivity) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                val am =
                    host.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                try {
                    when (call.method) {
                        "configureForVoiceCall" -> {
                            am.mode = AudioManager.MODE_IN_COMMUNICATION
                            val preferSpeaker = call.argument<Boolean>("preferSpeaker") ?: false
                            if (preferSpeaker) {
                                routeToSpeaker(am, true)
                            }
                            result.success("in_communication")
                        }
                        "setSpeakerOn" -> {
                            val on = call.argument<Boolean>("on") ?: false
                            routeToSpeaker(am, on)
                            result.success(on)
                        }
                        "resetAudioSession" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                am.clearCommunicationDevice()
                            } else {
                                @Suppress("DEPRECATION")
                                am.isSpeakerphoneOn = false
                            }
                            am.mode = AudioManager.MODE_NORMAL
                            releaseProximityWakeLock()
                            result.success(null)
                        }
                        "setProximityMonitoring" -> {
                            val on = call.argument<Boolean>("on") ?: false
                            if (on) acquireProximityWakeLock(host) else releaseProximityWakeLock()
                            result.success(on)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("AUDIO_SESSION_ERROR", e.message, null)
                }
            }
    }

    private fun acquireProximityWakeLock(host: FlutterActivity) {
        if (proximityWakeLock == null) {
            val pm = host.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) return
            proximityWakeLock = pm.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "lingolabuddy:voiceCallProximity",
            )
        }
        val lock = proximityWakeLock ?: return
        if (!lock.isHeld) lock.acquire()
    }

    private fun releaseProximityWakeLock() {
        val lock = proximityWakeLock ?: return
        if (lock.isHeld) {
            lock.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY)
        }
        proximityWakeLock = null
    }

    private fun routeToSpeaker(am: AudioManager, speakerOn: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = am.availableCommunicationDevices
            val target = if (speakerOn) {
                devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            } else {
                devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
            }
            if (target != null) {
                am.setCommunicationDevice(target)
            } else {
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn = speakerOn
            }
        } else {
            @Suppress("DEPRECATION")
            am.isSpeakerphoneOn = speakerOn
        }
    }
}

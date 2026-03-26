package com.velorastudios.earndash

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MotionTrackingStore.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundTracking" -> {
                    MotionTrackingStore.setAutoStart(this, true)
                    val intent = Intent(this, StepForegroundService::class.java).apply {
                        action = StepForegroundService.ACTION_START
                    }
                    ContextCompat.startForegroundService(this, intent)
                    result.success(true)
                }

                "stopForegroundTracking" -> {
                    MotionTrackingStore.setAutoStart(this, false)
                    val intent = Intent(this, StepForegroundService::class.java).apply {
                        action = StepForegroundService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }

                "getTrackingSnapshot" -> result.success(
                    MotionTrackingStore.getSnapshot(this),
                )

                else -> result.notImplemented()
            }
        }
    }
}

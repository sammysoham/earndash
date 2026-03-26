package com.velorastudios.earndash

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        if (!MotionTrackingStore.shouldAutoStart(context)) {
            return
        }

        val serviceIntent = Intent(context, StepForegroundService::class.java).apply {
            this.action = StepForegroundService.ACTION_START
        }
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}

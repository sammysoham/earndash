package com.velorastudios.earndash

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder

class StepForegroundService : Service(), SensorEventListener {
    companion object {
        const val ACTION_START = "com.velorastudios.earndash.action.START_STEP_TRACKING"
        const val ACTION_STOP = "com.velorastudios.earndash.action.STOP_STEP_TRACKING"
        private const val CHANNEL_ID = "earndash_move_tracking"
        private const val NOTIFICATION_ID = 17041
    }

    private var sensorManager: SensorManager? = null
    private var stepCounter: Sensor? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounter = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        MotionTrackingStore.setSupported(this, stepCounter != null)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTracking()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            else -> {
                startForeground(NOTIFICATION_ID, buildNotification())
                startTracking()
                return START_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onSensorChanged(event: SensorEvent?) {
        val sensorEvent = event ?: return
        if (sensorEvent.sensor.type == Sensor.TYPE_STEP_COUNTER) {
            MotionTrackingStore.updateStepCounter(this, sensorEvent.values.first().toInt())
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun startTracking() {
        val sensor = stepCounter
        if (sensor == null) {
            MotionTrackingStore.setSupported(this, false)
            return
        }

        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        MotionTrackingStore.setRunning(this, true)
        MotionTrackingStore.setSupported(this, true)
    }

    private fun stopTracking() {
        sensorManager?.unregisterListener(this)
        MotionTrackingStore.setRunning(this, false)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Move tracking",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps EarnDash step tracking active in the background."
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("EarnDash is tracking your steps")
            .setContentText("Move & Earn stays active while you walk.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
    }
}

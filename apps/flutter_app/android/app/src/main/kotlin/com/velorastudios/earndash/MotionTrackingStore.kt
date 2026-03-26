package com.velorastudios.earndash

import android.content.Context
import java.time.LocalDate
import java.time.format.DateTimeFormatter

object MotionTrackingStore {
    const val CHANNEL_NAME = "com.velorastudios.earndash/motion_tracking"

    private const val PREFS_NAME = "earndash_motion_tracking"
    private const val KEY_CURRENT_DAY = "current_day"
    private const val KEY_BASELINE_STEPS = "baseline_steps"
    private const val KEY_TODAY_STEPS = "today_steps"
    private const val KEY_LAST_RAW_STEPS = "last_raw_steps"
    private const val KEY_RUNNING = "running"
    private const val KEY_SUPPORTED = "supported"
    private const val KEY_LAST_SENSOR_AT = "last_sensor_at"
    private const val KEY_AUTO_START = "auto_start"

    private val formatter: DateTimeFormatter = DateTimeFormatter.ISO_LOCAL_DATE

    fun updateStepCounter(context: Context, rawSteps: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = currentDay()
        val storedDay = prefs.getString(KEY_CURRENT_DAY, null)

        if (storedDay == null || storedDay != today) {
            prefs.edit()
                .putString(KEY_CURRENT_DAY, today)
                .putInt(KEY_BASELINE_STEPS, rawSteps)
                .putInt(KEY_TODAY_STEPS, 0)
                .putInt(KEY_LAST_RAW_STEPS, rawSteps)
                .putLong(KEY_LAST_SENSOR_AT, System.currentTimeMillis())
                .apply()
            return
        }

        val baseline = prefs.getInt(KEY_BASELINE_STEPS, rawSteps)
        val steps = (rawSteps - baseline).coerceAtLeast(0)
        prefs.edit()
            .putInt(KEY_LAST_RAW_STEPS, rawSteps)
            .putInt(KEY_TODAY_STEPS, steps)
            .putLong(KEY_LAST_SENSOR_AT, System.currentTimeMillis())
            .apply()
    }

    fun setRunning(context: Context, running: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_RUNNING, running)
            .apply()
    }

    fun setSupported(context: Context, supported: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_SUPPORTED, supported)
            .apply()
    }

    fun setAutoStart(context: Context, autoStart: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_AUTO_START, autoStart)
            .apply()
    }

    fun shouldAutoStart(context: Context): Boolean =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_AUTO_START, false)

    fun getSnapshot(context: Context): Map<String, Any> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = currentDay()
        val storedDay = prefs.getString(KEY_CURRENT_DAY, today) ?: today
        val todaySteps = if (storedDay == today) prefs.getInt(KEY_TODAY_STEPS, 0) else 0

        return mapOf(
            "supported" to prefs.getBoolean(KEY_SUPPORTED, true),
            "running" to prefs.getBoolean(KEY_RUNNING, false),
            "autoStart" to prefs.getBoolean(KEY_AUTO_START, false),
            "todayDateKey" to today,
            "todaySteps" to todaySteps,
            "lastSensorAt" to prefs.getLong(KEY_LAST_SENSOR_AT, 0L),
            "source" to "android_foreground_service",
        )
    }

    private fun currentDay(): String = LocalDate.now().format(formatter)
}

package app.dawaei.dawaei

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val alarmChannel = "app.dawaei.dawaei/medication_alarm"
    private val startupChannel = "app.dawaei.dawaei/startup"
    private val activityLaunchElapsedRealtime = SystemClock.elapsedRealtime()
    private var alarmPlayer: MediaPlayer? = null
    private var activityIsResumed = false
    private var closeActivityForCurrentAlarm = false

    override fun onResume() {
        super.onResume()
        activityIsResumed = true
    }

    override fun onPause() {
        activityIsResumed = false
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        val notificationPayload = intent.getStringExtra("payload")
        if (notificationPayload?.contains("\"medicationId\"") == true) {
            // A running Activity that was already foregrounded belongs to the
            // user's current session. If Android brings a stopped Activity up
            // for a medication alarm, dismissal should finish that Activity.
            closeActivityForCurrentAlarm = !activityIsResumed
        }
        setIntent(intent)
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, startupChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSplashRemainingMillis" -> {
                        val elapsed =
                            SystemClock.elapsedRealtime() - activityLaunchElapsedRealtime
                        result.success((5_000L - elapsed).coerceAtLeast(0L).toInt())
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shouldCloseAlarmActivity" -> {
                        val shouldClose = closeActivityForCurrentAlarm
                        closeActivityForCurrentAlarm = false
                        result.success(shouldClose)
                    }
                    "canUseFullScreenIntent" -> {
                        val allowed = if (Build.VERSION.SDK_INT >= 34) {
                            getSystemService(NotificationManager::class.java)
                                .canUseFullScreenIntent()
                        } else {
                            true
                        }
                        result.success(allowed)
                    }
                    "isBatteryOptimizationIgnored" -> {
                        val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            getSystemService(PowerManager::class.java)
                                .isIgnoringBatteryOptimizations(packageName)
                        } else {
                            true
                        }
                        result.success(allowed)
                    }
                    "openBatterySettings" -> {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        result.success(null)
                    }
                    "openNotificationChannelSettings" -> {
                        val channelId = call.argument<String>("channelId")
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && channelId != null) {
                            startActivity(
                                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                    .putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                            )
                        } else {
                            startActivity(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    .setData(Uri.parse("package:$packageName"))
                            )
                        }
                        result.success(null)
                    }
                    "start" -> {
                        try {
                            startMedicationAlarm()
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("ALARM_AUDIO", "Could not start medication alarm audio", error.message)
                        }
                    }
                    "stop" -> {
                        stopMedicationAlarm()
                        result.success(null)
                    }
                    "finishAlarmActivity" -> {
                        // Cancel only the notification that opened this alarm;
                        // scheduled notifications for other doses are untouched.
                        call.argument<Int>("notificationId")?.let { id ->
                            getSystemService(NotificationManager::class.java).cancel(id)
                        }
                        stopMedicationAlarm()
                        // Clear lock-screen presentation for this Activity before
                        // finishing so Android restores the keyguard if it was locked.
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            setShowWhenLocked(false)
                            setTurnScreenOn(false)
                        } else {
                            @Suppress("DEPRECATION")
                            window.clearFlags(
                                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        }
                        result.success(null)
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startMedicationAlarm() {
        if (alarmPlayer?.isPlaying == true) return
        stopMedicationAlarm()

        val player = MediaPlayer()
        player.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        player.setDataSource(
            this,
            Uri.parse("android.resource://${packageName}/${R.raw.medication_alarm}")
        )
        player.isLooping = true
        player.setOnPreparedListener { prepared ->
            if (alarmPlayer === prepared) {
                prepared.start()
            } else {
                prepared.release()
            }
        }
        player.setOnErrorListener { mediaPlayer, _, _ ->
            mediaPlayer.release()
            if (alarmPlayer === mediaPlayer) alarmPlayer = null
            true
        }
        alarmPlayer = player
        player.prepareAsync()
    }

    private fun stopMedicationAlarm() {
        alarmPlayer?.let { player ->
            alarmPlayer = null
            try {
                if (player.isPlaying) player.stop()
            } catch (_: IllegalStateException) {
                // The player may still be preparing when the user stops the alarm.
            }
            player.release()
        }
    }

    override fun onDestroy() {
        stopMedicationAlarm()
        super.onDestroy()
    }
}

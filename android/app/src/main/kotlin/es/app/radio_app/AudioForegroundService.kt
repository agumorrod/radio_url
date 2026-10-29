package es.app.radio_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
/**
 * Foreground Service nativo que mantiene el proceso vivo
 * aunque la pantalla esté apagada o la app en segundo plano.
 * just_audio gestiona el audio; este servicio solo mantiene
 * la notificación persistente que impide que Android mate el proceso.
 */
class AudioForegroundService : Service() {

    companion object {
        const val CHANNEL_ID      = "radio_trebujena_channel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START    = "ACTION_START"
        const val ACTION_STOP     = "ACTION_STOP"
        const val ACTION_PAUSE    = "ACTION_PAUSE"
        const val ACTION_RESUME   = "ACTION_RESUME"
        const val EXTRA_TITLE     = "EXTRA_TITLE"
        const val EXTRA_SUBTITLE  = "EXTRA_SUBTITLE"
    }

    private var isPlaying = true
    private var title     = "Radio Trebujena"
    private var subtitle  = "En directo"

    // Handler en el main thread para llamar a Flutter de forma segura
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        title    = intent?.getStringExtra(EXTRA_TITLE)    ?: title
        subtitle = intent?.getStringExtra(EXTRA_SUBTITLE) ?: subtitle

        when (intent?.action) {
            ACTION_START -> {
                isPlaying = true
                startForeground(NOTIFICATION_ID, buildNotification())
            }
            ACTION_PAUSE -> {
                isPlaying = false
                updateNotification()
                // Llamamos a Flutter en el main thread
                mainHandler.post {
                    MainActivity.flutterChannel?.invokeMethod("onPause", null)
                }
            }
            ACTION_RESUME -> {
                isPlaying = true
                updateNotification()
                mainHandler.post {
                    MainActivity.flutterChannel?.invokeMethod("onResume", null)
                }
            }
            ACTION_STOP -> {
                mainHandler.post {
                    MainActivity.flutterChannel?.invokeMethod("onStop", null)
                }
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY // Android reiniciará el servicio si lo mata
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Radio Trebujena",
            NotificationManager.IMPORTANCE_LOW // IMPORTANCE_LOW = sin sonido
        ).apply {
            description = "Reproducción de audio en segundo plano"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun updateNotification() {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        // Al pulsar la notificación, abre la app
        val openIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }
        val openPending = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleAction = if (isPlaying) ACTION_PAUSE else ACTION_RESUME
        val toggleIcon   = if (isPlaying)
            android.R.drawable.ic_media_pause
        else
            android.R.drawable.ic_media_play
        val toggleLabel  = if (isPlaying) "Pausar" else "Reproducir"

        val togglePending = PendingIntent.getService(
            this, 1,
            Intent(this, AudioForegroundService::class.java).apply {
                action = toggleAction
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopPending = PendingIntent.getService(
            this, 2,
            Intent(this, AudioForegroundService::class.java).apply {
                action = ACTION_STOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openPending)
            .setOngoing(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(toggleIcon, toggleLabel, togglePending)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Parar",
                stopPending
            )
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setShowActionsInCompactView(0)
            )
            .build()
    }
}
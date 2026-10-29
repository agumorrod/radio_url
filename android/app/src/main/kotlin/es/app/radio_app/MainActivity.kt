package es.app.radio_app

import android.content.Intent
// import android.content.pm.PackageManager
// import android.os.Build
// import androidx.core.app.ActivityCompat
// import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "es.app.radio_app/foreground"
    // private val NOTIFICATION_PERMISSION_CODE = 100

    companion object {
        // Referencia estática al canal para que el servicio pueda
        // llamar a Flutter directamente sin broadcasts
        var flutterChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Pedir permiso de notificaciones en Android 13+
        // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        //     if (ContextCompat.checkSelfPermission(
        //             this, android.Manifest.permission.POST_NOTIFICATIONS
        //         ) != PackageManager.PERMISSION_GRANTED
        //     ) {
        //         ActivityCompat.requestPermissions(
        //             this,
        //             arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
        //             NOTIFICATION_PERMISSION_CODE
        //         )
        //     }
        // }

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        )

        // Guardamos referencia estática para que AudioForegroundService pueda usarla
        flutterChannel = channel

        channel.setMethodCallHandler { call, result ->
            val intent = Intent(this, AudioForegroundService::class.java)
            when (call.method) {
                "startService" -> {
                    intent.action = AudioForegroundService.ACTION_START
                    intent.putExtra(
                        AudioForegroundService.EXTRA_TITLE,
                        call.argument("title") ?: "Radio Trebujena"
                    )
                    intent.putExtra(
                        AudioForegroundService.EXTRA_SUBTITLE,
                        call.argument("subtitle") ?: "En directo"
                    )
                    startForegroundService(intent)
                    result.success(null)
                }
                "pauseService" -> {
                    intent.action = AudioForegroundService.ACTION_PAUSE
                    startService(intent)
                    result.success(null)
                }
                "resumeService" -> {
                    intent.action = AudioForegroundService.ACTION_RESUME
                    startService(intent)
                    result.success(null)
                }
                "stopService" -> {
                    intent.action = AudioForegroundService.ACTION_STOP
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        flutterChannel = null
        super.onDestroy()
    }
}
package com.example.acolle1

import android.app.role.RoleManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "acolle/caller_id"
        private const val PREFS = "acolle_caller_id"
        private const val NUMBERS_KEY = "suspect_numbers"
        private const val ROLE_REQUEST_CODE = 7412

        // Novo: canais do Notification Listener
        private const val CHANNEL_NOTIF_METODOS = "com.example.acolle1/notification_settings"
        private const val CHANNEL_NOTIF_EVENTOS = "com.example.acolle1/notification_events"
    }

    // Novo: sink do EventChannel para mandar notificações capturadas ao Dart
    private var eventSink: EventChannel.EventSink? = null

    // Novo: receiver que escuta o broadcast enviado pelo NotificationListener.kt
    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val pacote = intent.getStringExtra("pacote") ?: ""
            val titulo = intent.getStringExtra("titulo") ?: ""
            val texto = intent.getStringExtra("texto") ?: ""

            eventSink?.success(
                mapOf(
                    "pacote" to pacote,
                    "titulo" to titulo,
                    "texto" to texto
                )
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal já existente: call screening / overlay / suspect numbers
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestScreeningRole" -> requestScreeningRole(result)
                    "requestOverlayPermission" -> requestOverlayPermission(result)
                    "isScreeningRoleEnabled" -> result.success(isScreeningRoleEnabled())
                    "isOverlayPermissionEnabled" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this),
                    )
                    "syncSuspectNumbers" -> {
                        val numbers = call.argument<List<String>>("numbers").orEmpty()
                        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                            .edit()
                            .putStringSet(NUMBERS_KEY, numbers.toSet())
                            .apply()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Novo: canal de métodos do Notification Listener (permissão)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NOTIF_METODOS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissaoConcedida" -> {
                        val habilitados = Settings.Secure.getString(
                            contentResolver, "enabled_notification_listeners"
                        )
                        val concedida = habilitados?.contains(packageName) == true
                        result.success(concedida)
                    }
                    "abrirConfiguracoes" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Novo: canal de eventos (stream) do Notification Listener
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NOTIF_EVENTOS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver(
                        notificationReceiver,
                        IntentFilter("com.example.acolle1.NOVA_NOTIFICACAO"),
                        Context.RECEIVER_EXPORTED
                    )
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterReceiver(notificationReceiver)
                }
            })
    }

    private fun isScreeningRoleEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val roleManager = getSystemService(RoleManager::class.java)
        return roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) &&
            roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun requestOverlayPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)) {
            result.success(true)
            return
        }
        startActivity(
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            ),
        )
        result.success(false)
    }

    private fun requestScreeningRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false)
            return
        }

        val roleManager = getSystemService(RoleManager::class.java)
        if (!roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(false)
            return
        }
        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(true)
            return
        }

        startActivityForResult(
            roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING),
            ROLE_REQUEST_CODE,
        )
        // A escolha é feita na tela do Android; uma próxima chamada confirma
        // novamente se o papel já foi concedido.
        result.success(false)
    }
}
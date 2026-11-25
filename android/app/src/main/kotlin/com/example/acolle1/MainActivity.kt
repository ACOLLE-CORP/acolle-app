package com.example.acolle1

import android.app.role.RoleManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "acolle/caller_id"
        private const val CONTACT_REQUEST_CODE = 7413
        private const val ROLE_REQUEST_CODE = 7412

        private const val CHANNEL_NOTIF_METODOS = "com.example.acolle1/notification_settings"
        private const val CHANNEL_NOTIF_EVENTOS = "com.example.acolle1/notification_events"

        // Novo: canal do botão flutuante
        private const val CHANNEL_BOTAO_FLUTUANTE = "acolle/floating_button"
        private const val CHANNEL_ROTAS_BOTAO = "acolle/floating_button_routes"
    }

    private var pendingContact: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var floatingRouteSink: EventChannel.EventSink? = null
    private var notificationReceiverRegistered = false

    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val pacote = intent.getStringExtra("pacote") ?: ""
            val titulo = intent.getStringExtra("titulo") ?: ""
            val texto = intent.getStringExtra("texto") ?: ""

            eventSink?.success(
                mapOf(
                    "pacote" to pacote,
                    "titulo" to titulo,
                    "texto" to texto,
                    "classificacao" to (intent.getStringExtra("classificacao") ?: ""),
                    "risco" to intent.getIntExtra("risco", 0),
                    "recomendacao" to (intent.getStringExtra("recomendacao") ?: "")
                )
            )
        }
    }

    // Novo: garante que this.intent sempre reflita o toque mais recente
    // em uma opção do menu flutuante, mesmo se o app já estiver aberto
    // (launchMode singleTop/singleTask não atualiza getIntent() sozinho).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val rota = intent.getStringExtra(FloatingBubbleService.EXTRA_ROTA)
        if (rota != null && floatingRouteSink != null) {
            floatingRouteSink?.success(rota)
            intent.removeExtra(FloatingBubbleService.EXTRA_ROTA)
        }
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "acolle/contatos")
            .setMethodCallHandler { call, result ->
                if (call.method != "selecionarTelefone") result.notImplemented()
                else if (pendingContact != null) result.error("OCUPADO", "Agenda já aberta.", null)
                else {
                    pendingContact = result
                    try {
                        startActivityForResult(Intent(Intent.ACTION_PICK, Phone.CONTENT_URI), CONTACT_REQUEST_CODE)
                    } catch (error: RuntimeException) {
                        pendingContact = null
                        result.error("AGENDA", "Não foi possível abrir a agenda.", null)
                    }
                }
            }

        // Canal já existente: call screening / overlay / suspect numbers
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestScreeningRole" -> requestScreeningRole(result)
                    "requestOverlayPermission" -> requestOverlayPermission(result)
                    "isScreeningRoleEnabled" -> result.success(isScreeningRoleEnabled())
                    "areCallNotificationsEnabled" -> result.success(notificacoesDeChamadasAtivas())
                    "usesNotificationRuntimePermission" -> result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU,
                    )
                    "openCallNotificationSettings" -> {
                        criarCanalDeChamadas()
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val appNotificationsEnabled =
                                NotificationManagerCompat.from(this).areNotificationsEnabled()
                            val action = if (appNotificationsEnabled) {
                                Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS
                            } else {
                                Settings.ACTION_APP_NOTIFICATION_SETTINGS
                            }
                            startActivity(Intent(action).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                if (appNotificationsEnabled) {
                                    putExtra(Settings.EXTRA_CHANNEL_ID, CALL_ALERT_CHANNEL)
                                }
                            })
                        } else {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            })
                        }
                        result.success(null)
                    }
                    "isOverlayPermissionEnabled" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this),
                    )
                    "classificarChamada" -> {
                        val numero = call.argument<String>("numero").orEmpty()
                        kotlin.concurrent.thread {
                            val estado = try {
                                PhoneReputation.classificacao(applicationContext, numero)
                            } catch (_: Exception) { "indisponivel" }
                            runOnUiThread { result.success(estado) }
                        }
                    }
                    "isSavedContact" -> {
                        val numero = call.argument<String>("numero").orEmpty()
                        kotlin.concurrent.thread(name = "acolle-consulta-agenda") {
                            try {
                                val salvo = numero.isNotBlank() && applicationContext.contatoSalvo(numero)
                                runOnUiThread { result.success(salvo) }
                            } catch (erro: RuntimeException) {
                                runOnUiThread { result.error("AGENDA", "Consulta indisponível", null) }
                            }
                        }
                    }
                    "syncSuspectNumbers" -> {
                        val numbers = call.argument<List<String>>("numbers").orEmpty()
                        val prefs = getSharedPreferences(CALLER_ID_PREFS, Context.MODE_PRIVATE)
                        val editor = prefs.edit()
                        if (call.argument<Boolean>("confirmada") == true) {
                            editor.putStringSet(SUSPECT_NUMBERS_KEY, numbers.toSet())
                                .putLong(LISTA_CONFIRMADA_EM, System.currentTimeMillis())
                        } else {
                            val anterior = prefs.getStringSet(SUSPECT_NUMBERS_KEY, emptySet()).orEmpty()
                            editor.putStringSet(SUSPECT_NUMBERS_KEY, anterior + numbers)
                        }
                        editor.apply()
                        result.success(true)
                    }
                    "isSuspectNumberCached" -> {
                        val numero = call.argument<String>("numero").orEmpty()
                        result.success(applicationContext.numeroSuspeitoNoCache(numero))
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal de métodos do Notification Listener (permissão)
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
                    "avisosMensagemPermitidos" -> result.success(avisosMensagemPermitidos())
                    "abrirAjustesDeAvisos" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            criarCanalMensagens()
                            if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_CHANNEL_ID, CANAL_ALERTA_ID)
                            } else {
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            }.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal de eventos (stream) do Notification Listener
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NOTIF_EVENTOS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    if (!notificationReceiverRegistered) {
                        ContextCompat.registerReceiver(
                            this@MainActivity,
                            notificationReceiver,
                            IntentFilter("com.example.acolle1.NOVA_NOTIFICACAO"),
                            ContextCompat.RECEIVER_NOT_EXPORTED,
                        )
                        notificationReceiverRegistered = true
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    releaseNotificationReceiver()
                }
            })

        // Novo: canal do botão flutuante — ligar, desligar, e descobrir
        // se o app foi aberto por um toque no menu do botão.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BOTAO_FLUTUANTE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "iniciarBotao" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                            !Settings.canDrawOverlays(this)
                        ) {
                            result.error(
                                "OVERLAY_PERMISSION_REQUIRED",
                                "Autorize o Acolle a aparecer sobre outros aplicativos.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        ContextCompat.startForegroundService(
                            this,
                            Intent(this, FloatingBubbleService::class.java),
                        )
                        result.success(true)
                    }
                    "pararBotao" -> {
                        stopService(Intent(this, FloatingBubbleService::class.java))
                        result.success(true)
                    }
                    "isBotaoAtivo" -> result.success(FloatingBubbleService.emExecucao)
                    "rotaInicial" -> {
                        val rota = intent?.getStringExtra(FloatingBubbleService.EXTRA_ROTA)
                        // Consome a rota para não reabrir a mesma tela de novo
                        // se o Flutter perguntar outra vez mais tarde.
                        intent?.removeExtra(FloatingBubbleService.EXTRA_ROTA)
                        result.success(rota)
                    }


                    "textoTelaPendente" -> {
                        val prefs =
                            getSharedPreferences(
                                ScreenCaptureService.PREFS_CAPTURE,
                                Context.MODE_PRIVATE
                            )

                        val texto =
                            prefs.getString(
                                ScreenCaptureService.KEY_TEXTO_PENDENTE,
                                null
                            )

                        prefs
                            .edit()
                            .remove(
                                ScreenCaptureService.KEY_TEXTO_PENDENTE
                            )
                            .apply()

                        result.success(texto)
                    }


                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_ROTAS_BOTAO)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    floatingRouteSink = events
                }

                override fun onCancel(arguments: Any?) {
                    floatingRouteSink = null
                }
            })
    }

    private fun releaseNotificationReceiver() {
        if (notificationReceiverRegistered) {
            unregisterReceiver(notificationReceiver)
            notificationReceiverRegistered = false
        }
    }

    override fun onDestroy() {
        releaseNotificationReceiver()
        pendingContact?.success(null)
        pendingContact = null
        super.onDestroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CONTACT_REQUEST_CODE) return
        val result = pendingContact ?: return
        pendingContact = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            val contato = contentResolver.query(uri, arrayOf(Phone.DISPLAY_NAME, Phone.NUMBER), null, null, null)?.use {
                if (it.moveToFirst() && !it.getString(1).isNullOrBlank()) {
                    mapOf("nome" to it.getString(0).orEmpty(), "telefone" to it.getString(1))
                } else null
            }
            if (contato == null) result.error("SEM_NUMERO", "Escolha um contato com telefone.", null)
            else result.success(contato)
        } catch (error: RuntimeException) {
            result.error("LEITURA", "Não foi possível ler o contato selecionado.", null)
        }
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

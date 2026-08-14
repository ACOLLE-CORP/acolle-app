package com.example.acolle1

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class NotificationListener : NotificationListenerService() {

    private val executor = Executors.newCachedThreadPool()

    companion object {
        private const val BASE_URL = "https://acolle-api.onrender.com/analisar"
        private const val CANAL_ALERTA_ID = "acolle_alertas"
        private const val TIMEOUT_MS = 60_000

        private val pacotesMonitorados = setOf(
            "com.whatsapp",
            "com.google.android.apps.messaging",
            "com.android.mms",
        )

        private val regexLink = Regex(
            "(https?://\\S+)",
            RegexOption.IGNORE_CASE,
        )

        // Mesma tabela usada no fallback local do acolle_api.dart,
        // para manter consistência quando a API estiver fora do ar.
        private val dominiosSuspeitos = mapOf(
            "bancoserver.com" to 65,
            "login-bank.net" to 65,
            "verify-account.tk" to 95,
            "security-alert.com" to 95,
            "promo-premio.xyz" to 80,
            "golpista.online" to 90,
            "confirme-seus-dados.tk" to 95,
        )
        private val dominiosConfiados = setOf(
            "google.com", "facebook.com", "instagram.com",
            "youtube.com", "twitter.com", "github.com",
        )
    }

    override fun onCreate() {
        super.onCreate()
        criarCanalDeNotificacao()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        if (sbn.packageName !in pacotesMonitorados) return

        val extras = sbn.notification.extras
        val texto = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        if (texto.isBlank()) return

        // Roda em background: HTTP não pode ser feito na thread principal.
        executor.submit {
            try {
                val resultado = analisarConteudo(texto)
                processarResultado(texto, resultado)
            } catch (e: Exception) {
                // Falha de rede/API: se havia um link, cai no fallback local.
                val link = regexLink.find(texto)?.value
                if (link != null) {
                    val fallback = analisarLinkLocal(link)
                    processarResultado(texto, fallback)
                }
            }
        }
    }

    /// Decide se o texto tem um link (usa o mesmo formato de prompt do
    /// AcolleApi.analisarLink) ou é uma mensagem comum, e chama a API.
    private fun analisarConteudo(texto: String): JSONObject {
        val link = regexLink.find(texto)?.value

        val corpoTexto = if (link != null) {
            """
            Analise esta URL para identificar se é segura ou perigosa (golpe/phishing): $link
            Responda com: classificacao, risco numerico de 0 a 100, motivos e recomendacao.
            """.trimIndent()
        } else {
            texto
        }

        return chamarApi(corpoTexto)
    }

    private fun chamarApi(texto: String): JSONObject {
        val url = URL(BASE_URL)
        val conexao = url.openConnection() as HttpURLConnection

        try {
            conexao.requestMethod = "POST"
            conexao.setRequestProperty("Content-Type", "application/json")
            conexao.doOutput = true
            conexao.connectTimeout = TIMEOUT_MS
            conexao.readTimeout = TIMEOUT_MS

            val corpo = JSONObject().put("texto", texto).toString()
            conexao.outputStream.use { it.write(corpo.toByteArray(Charsets.UTF_8)) }

            if (conexao.responseCode != 200) {
                throw Exception("API retornou erro ${conexao.responseCode}")
            }

            val resposta = conexao.inputStream.bufferedReader().use { it.readText() }
            return JSONObject(resposta)
        } finally {
            conexao.disconnect()
        }
    }

    private fun analisarLinkLocal(link: String): JSONObject {
        for ((dominio, risco) in dominiosSuspeitos) {
            if (link.contains(dominio)) {
                return JSONObject()
                    .put("risco", risco)
                    .put("classificacao", if (risco >= 90) "Alto" else "Médio")
                    .put("recomendacao", "Não clique neste link. Pode conter malware ou roubar seus dados.")
            }
        }
        for (dominio in dominiosConfiados) {
            if (link.contains(dominio)) {
                return JSONObject()
                    .put("risco", 5)
                    .put("classificacao", "Baixo")
                    .put("recomendacao", "Link aparentemente seguro.")
            }
        }
        return JSONObject()
            .put("risco", 35)
            .put("classificacao", "Médio")
            .put("recomendacao", "Verifique o domínio em um buscador de confiança antes de abrir.")
    }

    private fun processarResultado(textoOriginal: String, resultado: JSONObject) {
        val classificacao = resultado.optString("classificacao", "Desconhecido")
        val risco = resultado.optInt("risco", 0)
        val recomendacao = resultado.optString("recomendacao", "")

        // Só alerta o idoso quando houver risco relevante — mensagens
        // "Baixo" não geram notificação, para não gerar excesso de alertas.
        if (classificacao == "Alto" || classificacao == "Médio") {
            mostrarNotificacaoAlerta(classificacao, risco, recomendacao)
        }

        // Mantém o broadcast para a UI do Flutter, agora já incluindo
        // o resultado pronto — assim, se o app estiver aberto, ele só
        // precisa EXIBIR o resultado, sem chamar a API de novo.
        val intent = Intent("com.example.acolle1.NOVA_NOTIFICACAO")
        intent.putExtra("texto", textoOriginal)
        intent.putExtra("classificacao", classificacao)
        intent.putExtra("risco", risco)
        intent.putExtra("recomendacao", recomendacao)
        sendBroadcast(intent)
    }

    private fun criarCanalDeNotificacao() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val canal = NotificationChannel(
            CANAL_ALERTA_ID,
            "Alertas de golpe",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Avisos quando o Acolle detecta uma mensagem ou link suspeito"
        }
        manager.createNotificationChannel(canal)
    }

    private fun mostrarNotificacaoAlerta(classificacao: String, risco: Int, recomendacao: String) {
        val emoji = if (classificacao == "Alto") "🚨" else "⚠️"

        val intentAbrirApp = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intentAbrirApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notificacao = NotificationCompat.Builder(this, CANAL_ALERTA_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("$emoji Risco $classificacao detectado ($risco%)")
            .setContentText(recomendacao)
            .setStyle(NotificationCompat.BigTextStyle().bigText(recomendacao))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(System.currentTimeMillis().toInt(), notificacao)
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
    }
}
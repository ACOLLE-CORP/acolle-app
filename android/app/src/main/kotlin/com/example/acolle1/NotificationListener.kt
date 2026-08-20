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
import android.speech.tts.TextToSpeech
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors

class NotificationListener : NotificationListenerService(), TextToSpeech.OnInitListener {

    private val executor = Executors.newCachedThreadPool()
    private var tts: TextToSpeech? = null

    companion object {
        private const val BASE_URL = "https://acolle-api.onrender.com/analisar"
        private const val WORKER_URL =
            "https://acolle-spam-check.acolle-corp.workers.dev/verificar"
        private const val CANAL_ALERTA_ID = "acolle_alertas"
        private const val TIMEOUT_MS = 60_000

        // Mesmas chaves usadas pelo AcolleCallScreeningService, para
        // compartilhar o cache de números suspeitos.
        private const val PREFS = "acolle_caller_id"
        private const val NUMBERS_KEY = "suspect_numbers"

        private val pacotesMonitorados = setOf(
            "com.whatsapp",
            "com.google.android.apps.messaging",
            "com.android.mms",
        )

        private val regexLink = Regex("(https?://\\S+)", RegexOption.IGNORE_CASE)

        // Textos que o WhatsApp usa para notificações de chamada
        // (cobre voz e vídeo; o app pode variar a formatação por versão).
        private val palavrasChamada = listOf("chamada de voz", "chamada de vídeo", "videochamada")

        // Captura números com formatação de telefone (com ou sem +55, DDD, etc).
        private val regexNumero = Regex("[+]?[0-9][0-9\\s().-]{7,}[0-9]")

        private val dominiosSuspeitos = mapOf(
            "bancoserver.com" to 65, "login-bank.net" to 65,
            "verify-account.tk" to 95, "security-alert.com" to 95,
            "promo-premio.xyz" to 80, "golpista.online" to 90,
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
        tts = TextToSpeech(this, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("pt", "BR")
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        if (sbn.packageName !in pacotesMonitorados) return

        val extras = sbn.notification.extras
        val titulo = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val texto = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        val ehChamadaWhatsApp = sbn.packageName == "com.whatsapp" &&
            (sbn.notification.category == Notification.CATEGORY_CALL ||
                palavrasChamada.any { it in titulo.lowercase() || it in texto.lowercase() })

        if (ehChamadaWhatsApp) {
            tratarChamadaWhatsApp(titulo, texto)
            return
        }

        // Fluxo já existente: mensagens de texto e links.
        if (texto.isBlank()) return
        executor.submit {
            try {
                val resultado = analisarConteudo(texto)
                processarResultadoMensagem(texto, resultado)
            } catch (e: Exception) {
                val link = regexLink.find(texto)?.value
                if (link != null) {
                    val fallback = analisarLinkLocal(link)
                    processarResultadoMensagem(texto, fallback)
                }
            }
        }
    }

    // ============================================================
    // NOVO: detecção de chamada de voz/vídeo do WhatsApp
    // ============================================================

    private fun tratarChamadaWhatsApp(titulo: String, texto: String) {
        // O número só aparece quando o remetente NÃO está salvo como
        // contato — que é justamente o caso mais comum de golpe.
        val numero = regexNumero.find("$titulo $texto")?.value ?: return
        val normalizado = normalizarNumero(numero)

        executor.submit {
            val suspeito = verificarNumeroSuspeito(normalizado)
            if (suspeito == true) {
                CallerAlertOverlay.show(this, numero, true)
                falarAlerta("Atenção! Chamada de vídeo ou voz suspeita de golpe no WhatsApp.")
            }
        }
    }

    private fun verificarNumeroSuspeito(numeroNormalizado: String): Boolean? {
        val cacheLocal = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(NUMBERS_KEY, emptySet())
            .orEmpty()
        if (cacheLocal.contains(numeroNormalizado)) return true

        return try {
            val conexao = URI(WORKER_URL).toURL().openConnection() as HttpURLConnection
            conexao.requestMethod = "POST"
            conexao.connectTimeout = 4_000
            conexao.readTimeout = 6_000
            conexao.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            conexao.doOutput = true
            conexao.outputStream.bufferedWriter(Charsets.UTF_8).use {
                it.write(JSONObject().put("numero", numeroNormalizado).toString())
            }
            if (conexao.responseCode !in 200..299) return null
            val payload = conexao.inputStream.bufferedReader().use { it.readText() }
            JSONObject(payload).optBoolean("suspeito", false)
        } catch (e: Exception) {
            null // falha de rede: não alerta, mas também não afirma segurança
        }
    }

    private fun normalizarNumero(numero: String): String {
        var digitos = numero.filter(Char::isDigit)
        if (digitos.startsWith("00")) digitos = digitos.drop(2)
        if ((digitos.length == 10 || digitos.length == 11) && !digitos.startsWith("55")) {
            digitos = "55$digitos"
        }
        return digitos
    }

    private fun falarAlerta(mensagem: String) {
        tts?.speak(mensagem, TextToSpeech.QUEUE_FLUSH, null, "acolle_alerta_whatsapp")
    }

    // ============================================================
    // Fluxo já existente: mensagens e links de texto
    // ============================================================

    private fun analisarConteudo(texto: String): JSONObject {
        val link = regexLink.find(texto)?.value
        val corpoTexto = if (link != null) {
            """
            Analise esta URL para identificar se é segura ou perigosa (golpe/phishing): $link
            Responda com: classificacao, risco numerico de 0 a 100, motivos e recomendacao.
            """.trimIndent()
        } else texto
        return chamarApi(corpoTexto)
    }

    private fun chamarApi(texto: String): JSONObject {
        val conexao = URL(BASE_URL).openConnection() as HttpURLConnection
        try {
            conexao.requestMethod = "POST"
            conexao.setRequestProperty("Content-Type", "application/json")
            conexao.doOutput = true
            conexao.connectTimeout = TIMEOUT_MS
            conexao.readTimeout = TIMEOUT_MS
            val corpo = JSONObject().put("texto", texto).toString()
            conexao.outputStream.use { it.write(corpo.toByteArray(Charsets.UTF_8)) }
            if (conexao.responseCode != 200) throw Exception("API retornou erro ${conexao.responseCode}")
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
                return JSONObject().put("risco", 5).put("classificacao", "Baixo")
                    .put("recomendacao", "Link aparentemente seguro.")
            }
        }
        return JSONObject().put("risco", 35).put("classificacao", "Médio")
            .put("recomendacao", "Verifique o domínio em um buscador de confiança antes de abrir.")
    }

    private fun processarResultadoMensagem(textoOriginal: String, resultado: JSONObject) {
        val classificacao = resultado.optString("classificacao", "Desconhecido")
        val risco = resultado.optInt("risco", 0)
        val recomendacao = resultado.optString("recomendacao", "")

        if (classificacao == "Alto" || classificacao == "Médio") {
            mostrarNotificacaoAlerta(classificacao, risco, recomendacao)
        }

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
        manager.createNotificationChannel(
            NotificationChannel(
                CANAL_ALERTA_ID, "Alertas de golpe", NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Avisos quando o Acolle detecta uma mensagem ou link suspeito" },
        )
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
        getSystemService(NotificationManager::class.java)
            .notify(System.currentTimeMillis().toInt(), notificacao)
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
        tts?.stop()
        tts?.shutdown()
    }
}
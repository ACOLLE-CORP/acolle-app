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
import java.util.Locale
import java.util.concurrent.Executors

class NotificationListener : NotificationListenerService(), TextToSpeech.OnInitListener {

    private val executor = Executors.newFixedThreadPool(2)
    private var tts: TextToSpeech? = null

    companion object {
        private const val BASE_URL = "https://acolle-ia.acolle-corp.workers.dev/analisar"
        private const val WORKER_URL =
            "https://acolle-spam-check.acolle-corp.workers.dev/verificar"
        private const val CANAL_ALERTA_ID = "acolle_alertas"
        private const val CONNECT_TIMEOUT_MS = 5_000
        private const val READ_TIMEOUT_MS = 30_000
        private const val DEDUP_WINDOW_MS = 24 * 60 * 60 * 1000L

        // Mesmas chaves usadas pelo AcolleCallScreeningService, para
        // compartilhar o cache de números suspeitos.
        private const val PREFS = "acolle_caller_id"
        private const val NUMBERS_KEY = "suspect_numbers"

        private val pacotesMonitorados = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
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
        if (sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = sbn.notification.extras
        val titulo = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val texto = extrairTextoNotificacao(extras)

        val ehChamadaWhatsApp = sbn.packageName in setOf("com.whatsapp", "com.whatsapp.w4b") &&
            (sbn.notification.category == Notification.CATEGORY_CALL ||
                palavrasChamada.any { it in titulo.lowercase() || it in texto.lowercase() })

        if (ehChamadaWhatsApp) {
            if (eventoDuplicado(sbn.packageName, titulo, "chamada:$texto")) return
            tratarChamadaWhatsApp(titulo, texto)
            return
        }

        if (sbn.notification.flags and Notification.FLAG_ONGOING_EVENT != 0) return
        val criado = sbn.notification.`when`
        if (!extras.containsKey(Notification.EXTRA_MESSAGES) &&
            criado > 0 && System.currentTimeMillis() - criado > 120_000) return
        if (texto.isBlank()) return
        if (eventoDuplicado(sbn.packageName, titulo, texto)) return

        executor.submit {
            try {
                val resultado = analisarConteudo(texto)
                processarResultadoMensagem(sbn.packageName, titulo, texto, resultado)
            } catch (e: Exception) {
                val fallback = analisarMensagemLocal(texto).put("origem", "local")
                processarResultadoMensagem(sbn.packageName, titulo, texto, fallback)
            }
        }
    }

    private fun extrairTextoNotificacao(extras: android.os.Bundle): String {
        // O array inclui histórico. Nunca reanalisar a conversa inteira a cada atualização.
        val mensagens = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        val ultima = mensagens?.mapNotNull { it as? android.os.Bundle }
            ?.maxByOrNull { it.getLong("time") }
        if (ultima != null) {
            val instante = ultima.getLong("time")
            if (instante > 0 && System.currentTimeMillis() - instante > 120_000) return ""
            return ultima.getCharSequence("text")?.toString()?.trim()?.take(4_000) ?: ""
        }
        return (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()?.trim()?.take(4_000) ?: ""
    }

    @Synchronized
    private fun eventoDuplicado(pacote: String, titulo: String, texto: String): Boolean {
        val agora = System.currentTimeMillis()
        val chave = java.security.MessageDigest.getInstance("SHA-256")
            .digest("$pacote\u0000$titulo\u0000${texto.trim()}".toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        val prefs = getSharedPreferences("acolle_eventos_processados", Context.MODE_PRIVATE)
        val anterior = prefs.getLong(chave, 0)
        if (agora - anterior < DEDUP_WINDOW_MS) return true
        val editor = prefs.edit()
        prefs.all.forEach { (key, value) ->
            if (value is Long && agora - value >= DEDUP_WINDOW_MS) editor.remove(key)
        }
        editor.putLong(chave, agora).apply()
        return false
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
        return chamarApi(sanitizarParaAnalise(texto))
    }

    private fun sanitizarParaAnalise(texto: String): String {
        return texto
            .replace(Regex("(?i)\\b\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}\\b"), "[CPF]")
            .replace(Regex("\\b(?:\\d[ -]*?){13,19}\\b"), "[CARTÃO]")
            .replace(Regex("(?i)\\b(?:código|codigo|token|senha)\\s*[:=-]?\\s*\\d{4,8}\\b"), "[CÓDIGO]")
            .replace(Regex("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"), "[EMAIL]")
            .take(4_000)
    }

    private fun chamarApi(texto: String): JSONObject {
        val conexao = URI(BASE_URL).toURL().openConnection() as HttpURLConnection
        try {
            conexao.requestMethod = "POST"
            conexao.setRequestProperty("Content-Type", "application/json")
            conexao.doOutput = true
            conexao.connectTimeout = CONNECT_TIMEOUT_MS
            conexao.readTimeout = READ_TIMEOUT_MS
            val corpo = JSONObject()
                .put("tipo", "mensagem")
                .put("texto", texto)
                .toString()
            conexao.outputStream.use { it.write(corpo.toByteArray(Charsets.UTF_8)) }
            if (conexao.responseCode != 200) throw Exception("API retornou erro ${conexao.responseCode}")
            val resposta = conexao.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(resposta)
            if (!json.has("risco") || !json.has("classificacao") || !json.has("recomendacao")) {
                throw Exception("API retornou uma análise incompleta")
            }
            return json
        } finally {
            conexao.disconnect()
        }
    }

    private fun analisarLinkLocal(link: String): JSONObject {
        for ((dominio, risco) in dominiosSuspeitos) {
            if (runCatching { URI(link).host?.lowercase() }.getOrNull()
                    ?.let { it == dominio || it.endsWith(".$dominio") } == true) {
                return JSONObject()
                    .put("risco", risco)
                    .put("classificacao", if (risco >= 90) "Alto" else "Médio")
                    .put("recomendacao", "Não clique neste link. Pode conter malware ou roubar seus dados.")
            }
        }
        for (dominio in dominiosConfiados) {
            if (runCatching { URI(link).host?.lowercase() }.getOrNull()
                    ?.let { it == dominio || it.endsWith(".$dominio") } == true) {
                return JSONObject().put("risco", 5).put("classificacao", "Baixo")
                    .put("recomendacao", "Link aparentemente seguro.")
            }
        }
        return JSONObject().put("risco", 35).put("classificacao", "Médio")
            .put("recomendacao", "Verifique o domínio em um buscador de confiança antes de abrir.")
    }

    private fun analisarMensagemLocal(texto: String): JSONObject {
        val link = regexLink.find(texto)?.value
        if (link != null) {
            val resultadoLink = analisarLinkLocal(link)
            if (resultadoLink.optInt("risco", 0) >= 65) return resultadoLink
        }

        val normalizado = texto.lowercase(Locale("pt", "BR"))
        var risco = if (link != null) 15 else 0
        val motivos = mutableListOf<String>()

        fun marcar(padrao: Regex, pontos: Int, motivo: String) {
            if (padrao.containsMatchIn(normalizado)) {
                risco += pontos
                motivos += motivo
            }
        }

        marcar(Regex("\\b(urgente|agora|imediatamente|última chance|ultima chance|bloquead[oa])\\b"), 20,
            "A mensagem tenta criar urgência ou medo.")
        marcar(Regex("\\b(senha|código|codigo|token|cvv|confirme seus dados|validar cadastro)\\b"), 30,
            "Há pedido de código, senha ou dados pessoais.")
        marcar(Regex("\\b(pix|transferência|transferencia|depósito|deposito|pague|pagamento|dinheiro)\\b"), 25,
            "Há pedido ou referência a pagamento.")
        marcar(Regex("\\b(troquei de número|troquei de numero|número novo|numero novo|sou eu|mãe|mae|pai|filho|filha|neto|neta)\\b"), 25,
            "A mensagem pode estar se passando por uma pessoa conhecida.")
        marcar(Regex("\\b(prêmio|premio|sorteio|benefício|beneficio|ganhou|resgate)\\b"), 25,
            "A mensagem promete prêmio ou benefício.")
        marcar(Regex("(acesso remoto|anydesk|teamviewer|instale este aplicativo|compartilhe sua tela)"), 45,
            "Há tentativa de obter acesso remoto ao aparelho.")

        risco = risco.coerceIn(0, 100)
        val classificacao = when {
            risco >= 70 -> "Alto"
            risco >= 30 -> "Médio"
            else -> "Baixo"
        }

        return JSONObject()
            .put("origem", "local")
            .put("risco", risco)
            .put("classificacao", classificacao)
            .put("motivos", org.json.JSONArray(motivos))
            .put("recomendacao", if (risco >= 30) {
                "Não responda, não clique e não faça pagamentos antes de confirmar por outro meio."
            } else {
                "Nenhum sinal forte foi identificado localmente. Continue atento."
            })
    }

    private fun processarResultadoMensagem(
        pacote: String,
        titulo: String,
        textoOriginal: String,
        resultado: JSONObject,
    ) {
        val risco = resultado.optInt("risco", 0).coerceIn(0, 100)
        val classificacaoRecebida = resultado.optString("classificacao", "")
        val classificacao = when (classificacaoRecebida.trim().lowercase(Locale("pt", "BR"))) {
            "alto", "alta", "high", "malicioso" -> "Alto"
            "médio", "medio", "média", "media", "medium", "suspeito" -> "Médio"
            "baixo", "baixa", "low", "confiável", "confiavel" -> "Baixo"
            else -> when {
                risco >= 70 -> "Alto"
                risco >= 30 -> "Médio"
                else -> "Baixo"
            }
        }
        val recomendacao = resultado.optString(
            "recomendacao",
            "Confirme a mensagem por outro meio antes de responder.",
        )

        val local = resultado.optString("origem") == "local"
        if (classificacao == "Alto" || (classificacao == "Médio" && !local)) {
            mostrarNotificacaoAlerta(classificacao, pacote,
                if (local) "Não foi possível consultar a IA. Por precaução, confirme por outro meio antes de agir."
                else recomendacao)
        }

        val intent = Intent("com.example.acolle1.NOVA_NOTIFICACAO").apply {
            setPackage(packageName)
            putExtra("pacote", pacote)
            putExtra("titulo", titulo)
            putExtra("texto", textoOriginal)
            putExtra("classificacao", classificacao)
            putExtra("risco", risco)
            putExtra("recomendacao", recomendacao)
        }
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

    @Synchronized
    private fun mostrarNotificacaoAlerta(classificacao: String, pacote: String, recomendacao: String) {
        val agora = System.currentTimeMillis()
        val prefs = getSharedPreferences("acolle_alerta_intervalo", Context.MODE_PRIVATE)
        val nivel = if (classificacao == "Alto") 2 else 1
        // Evita rajadas de avisos; permite escalada de Médio para Alto.
        if (agora - prefs.getLong("ultimo", 0) < 60_000 &&
            nivel <= prefs.getInt("nivel", 0)) return
        prefs.edit().putLong("ultimo", agora).putInt("nivel", nivel).apply()
        val origem = if (pacote.startsWith("com.whatsapp")) "WhatsApp" else "Mensagens SMS"
        val intentAbrirApp = Intent(this, MessageAlertActivity::class.java).apply {
            putExtra("recomendacao", recomendacao)
            putExtra("origem", origem)
            putExtra("alto", classificacao == "Alto")
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intentAbrirApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notificacao = NotificationCompat.Builder(this, CANAL_ALERTA_ID)
            .setSmallIcon(R.drawable.ic_acolle_notification)
            .setContentTitle(if (classificacao == "Alto") "Pare e confira: sinais de golpe" else "Confira esta mensagem com cuidado")
            .setSubText("Acolle • $origem")
            .setContentText(recomendacao)
            .setStyle(NotificationCompat.BigTextStyle().bigText(recomendacao))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .addAction(0, "Ver orientação", pendingIntent)
            .setAutoCancel(true)
            .setTimeoutAfter(120_000)
            .build()
        getSystemService(NotificationManager::class.java)
            .notify(9100, notificacao)
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
        tts?.stop()
        tts?.shutdown()
    }
}

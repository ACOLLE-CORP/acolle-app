package com.example.acolle1

import android.content.Context
import android.os.SystemClock
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.util.concurrent.ExecutionException
import java.util.concurrent.FutureTask

internal object PhoneReputation {
    private val consultas = ConsultaReputacao("https://acolle-spam-check.acolle-corp.workers.dev/verificar")

    fun normalize(number: String): String = normalizeCallerNumber(number)

    fun classificacao(context: Context, number: String): String = when {
        context.contatoSalvo(number) -> "contato"
        else -> avaliarNumero(context, number).chave
    }

    fun avaliarNumero(
        context: Context,
        number: String,
        consulta: ConsultaReputacao = consultas,
    ): CallAlertStatus = when {
        context.numeroSuspeitoNoCache(number) -> CallAlertStatus.SUSPECT
        normalize(number).length !in 10..15 -> CallAlertStatus.INCOMPLETE
        else -> try {
            if (consulta.verificar(number)) CallAlertStatus.SUSPECT else CallAlertStatus.CLEAR
        } catch (e: Exception) {
            android.util.Log.w(CALL_ALERT_TAG, "Consulta externa de reputação falhou", e)
            val ultimaLista = context.getSharedPreferences(CALLER_ID_PREFS, Context.MODE_PRIVATE)
                .getLong(LISTA_CONFIRMADA_EM, 0L)
            when {
                context.numeroSuspeitoNoCache(number) -> CallAlertStatus.SUSPECT
                ultimaLista > 0 && System.currentTimeMillis() - ultimaLista in 0L..86_400_000L -> CallAlertStatus.LOCAL_ONLY
                else -> CallAlertStatus.UNAVAILABLE
            }
        }
    }
}

internal class ConsultaReputacao(private val url: String, private val aguardar: (Long) -> Unit = Thread::sleep) {
    private val respostas = mutableMapOf<String, Pair<Long, Boolean>>()
    private val emAndamento = mutableMapOf<String, FutureTask<Boolean>>()

    fun verificar(number: String): Boolean {
        val normalized = normalizeCallerNumber(number)
        require(normalized.length in 10..15) { "Número inválido para consulta" }
        val tarefa = synchronized(this) {
            val agora = SystemClock.elapsedRealtime()
            respostas.entries.removeAll { agora - it.value.first >= 30_000 }
            respostas[normalized]?.let { return it.second }
            emAndamento.getOrPut(normalized) {
                FutureTask {
                    val resultado = consultarComNovaTentativa(normalized)
                    synchronized(this) { respostas[normalized] = SystemClock.elapsedRealtime() to resultado }
                    resultado
                }
            }
        }
        // A chamada e o histórico podem pedir o mesmo número ao mesmo tempo.
        tarefa.run()
        return try {
            tarefa.get()
        } catch (e: ExecutionException) {
            throw e.cause ?: e
        } finally {
            synchronized(this) {
                if (tarefa.isDone && emAndamento[normalized] === tarefa) emAndamento.remove(normalized)
            }
        }
    }

    private class FalhaHttp(status: Int, val espera: Long?) : IOException("Consulta respondeu HTTP $status")

    private fun consultarComNovaTentativa(numero: String): Boolean {
        try {
            return consultar(numero)
        } catch (e: FalhaHttp) {
            aguardar(e.espera ?: throw e)
        } catch (e: IOException) {
            if (e is javax.net.ssl.SSLException || Thread.currentThread().isInterrupted) throw e
            aguardar(500)
        }
        return consultar(numero)
    }

    private fun consultar(normalized: String): Boolean {
        val connection = URI(url).toURL().openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"
            connection.connectTimeout = 4_000
            connection.readTimeout = 6_000
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            connection.doOutput = true
            connection.outputStream.bufferedWriter(Charsets.UTF_8).use {
                it.write(JSONObject().put("numero", "+$normalized").toString())
            }
            val status = connection.responseCode
            if (status !in 200..299) {
                val espera = when (status) {
                    500, 502, 503, 504 -> 500L
                    429 -> {
                        val segundos = connection.getHeaderField("Retry-After")?.toLongOrNull()
                        if (segundos != null) segundos.takeIf { it in 0..10 }?.times(1000L)
                        else {
                            val erro = connection.errorStream?.bufferedReader()?.use { it.readText() }
                            if (erro != null && runCatching { JSONObject(erro).optString("error") }.getOrNull() ==
                                "Tente novamente em instantes") 10_000L else null
                        }
                    }
                    else -> null
                }
                throw FalhaHttp(status, espera)
            }
            val payload = connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            return JSONObject(payload).getBoolean("suspeito")
        } finally {
            connection.disconnect()
        }
    }
}

package com.example.acolle1

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI

internal object PhoneReputation {
    private const val WORKER_URL =
        "https://acolle-spam-check.acolle-corp.workers.dev/verificar"

    fun normalize(number: String): String = normalizeCallerNumber(number)

    fun check(number: String): Boolean {
        val normalized = normalize(number)
        require(normalized.length in 10..15) { "Número inválido para consulta" }
        val connection = URI(WORKER_URL).toURL().openConnection() as HttpURLConnection
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
            if (status !in 200..299) error("Worker respondeu HTTP $status")
            val payload = connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            return JSONObject(payload).getBoolean("suspeito")
        } finally {
            connection.disconnect()
        }
    }
}

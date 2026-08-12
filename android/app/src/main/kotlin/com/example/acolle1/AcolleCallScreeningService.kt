package com.example.acolle1

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import kotlin.concurrent.thread

class AcolleCallScreeningService : CallScreeningService() {
    companion object {
        private const val PREFS = "acolle_caller_id"
        private const val NUMBERS_KEY = "suspect_numbers"
        // v2 cria um canal novo: propriedades como bypass do Não Perturbe são
        // imutáveis depois que um canal já foi criado pelo Android/MIUI.
        private const val CHANNEL_ID = "acolle_call_alerts_v2"
        // Substituido automaticamente pelo endereco retornado no primeiro deploy.
        private const val WORKER_URL =
            "https://acolle-spam-check.acolle-corp.workers.dev/verificar"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        // O Android exige uma resposta rápida. O Acolle nunca bloqueia nem
        // silencia a ligação: ele apenas classifica e avisa.
        respondToCall(callDetails, CallResponse.Builder().build())

        val rawNumber = callDetails.handle?.schemeSpecificPart.orEmpty()
        if (rawNumber.isBlank()) return
        val normalized = normalize(rawNumber)
        val suspectNumbers = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(NUMBERS_KEY, emptySet())
            .orEmpty()
        val isSuspect = suspectNumbers.contains(normalized)
        Log.i(
            "AcolleCallerId",
            "Chamada recebida; numero=$normalized suspeito=$isSuspect cache=${suspectNumbers.size}",
        )
        if (isSuspect) {
            val overlayShown = CallerAlertOverlay.show(this, rawNumber, true)
            if (!overlayShown) openAlertScreen(rawNumber, true)
            showAlert(rawNumber, true)
        } else {
            // Nunca apresenta "seguro" antes de a base externa responder.
            CallerAlertOverlay.show(this, rawNumber, null)
            verifyWithOpenSpam(rawNumber)
        }
    }

    private fun verifyWithOpenSpam(number: String) {
        if (WORKER_URL.isBlank()) {
            CallerAlertOverlay.hide(this)
            showVerificationFailure(number)
            return
        }
        thread(name = "acolle-openspam-check") {
            try {
                val connection = URI(WORKER_URL).toURL()
                    .openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.connectTimeout = 4_000
                connection.readTimeout = 6_000
                connection.setRequestProperty("Accept", "application/json")
                connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                connection.doOutput = true
                connection.outputStream.bufferedWriter(Charsets.UTF_8).use {
                    it.write(JSONObject().put("numero", number).toString())
                }
                if (connection.responseCode !in 200..299) {
                    throw IllegalStateException("Worker respondeu ${connection.responseCode}")
                }
                val payload = connection.inputStream.bufferedReader().use { it.readText() }
                val suspect = JSONObject(payload).optBoolean("suspeito", false)
                CallerAlertOverlay.show(this, number, suspect)
                showAlert(number, suspect)
                Log.i("AcolleCallerId", "OpenSpam respondeu; suspeito=$suspect")
            } catch (error: Exception) {
                Log.e("AcolleCallerId", "Falha ao consultar OpenSpam", error)
                CallerAlertOverlay.hide(this)
                showVerificationFailure(number)
            }
        }
    }

    private fun showVerificationFailure(number: String) {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Alertas de chamadas",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }
        val warning = "Tenha cuidado: não informe senhas nem códigos por telefone."
        manager.notify(
            normalizedNotificationId(number),
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("Não foi possível verificar a chamada")
                .setContentText(warning)
                .setStyle(NotificationCompat.BigTextStyle().bigText(warning))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build(),
        )
    }

    private fun openAlertScreen(number: String, isSuspect: Boolean) {
        try {
            startActivity(
                Intent(this, IncomingCallAlertActivity::class.java).apply {
                    putExtra(IncomingCallAlertActivity.EXTRA_NUMBER, number)
                    putExtra(IncomingCallAlertActivity.EXTRA_SUSPECT, isSuspect)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                },
            )
            Log.i("AcolleCallerId", "Tela de alerta solicitada diretamente")
        } catch (error: Exception) {
            // Alguns fabricantes proíbem Activity em segundo plano. Nesses
            // casos, a notificação de tela cheia abaixo permanece disponível.
            Log.e("AcolleCallerId", "Fabricante bloqueou a tela direta", error)
        }
    }

    private fun showAlert(number: String, isSuspect: Boolean) {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Alertas de chamadas",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Avisa se uma chamada pode estar associada a golpes"
                    enableVibration(true)
                    // O aparelho pode estar em Não Perturbe justamente durante
                    // uma chamada. Como o usuário já autorizou o acesso à
                    // política de notificações, este alerta de segurança não
                    // deve ser escondido pelo filtro do sistema.
                    setBypassDnd(true)
                },
            )
        }

        val notificationId = normalizedNotificationId(number)
        val showAlert = PendingIntent.getActivity(
            this,
            notificationId,
            Intent(this, IncomingCallAlertActivity::class.java).apply {
                putExtra(IncomingCallAlertActivity.EXTRA_NUMBER, number)
                putExtra(IncomingCallAlertActivity.EXTRA_SUSPECT, isSuspect)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val title = if (isSuspect) "⚠️ Possível chamada de golpe" else "Chamada verificada pelo Acolle"
        val message = if (isSuspect) {
            "$number está na lista de números denunciados. Não informe senhas ou códigos."
        } else {
            "Nenhuma denúncia encontrada para $number. Isso não garante que a ligação seja segura."
        }
        val color = if (isSuspect) Color.RED else Color.rgb(46, 125, 50)

        manager.notify(
            notificationId,
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setColor(color)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                // CATEGORY_CALL faz o Android/MIUI submeter este aviso ao
                // filtro de ligações do modo Não Perturbe e pode ocultá-lo.
                // Este é um alerta informativo, não a própria chamada.
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setContentIntent(showAlert)
                // Exibe o cartão mesmo sobre o discador ou com o Acolle fechado.
                // Se o fabricante impedir tela cheia, a mesma informação ainda
                // aparece como notificação heads-up de alta prioridade.
                .setFullScreenIntent(showAlert, true)
                .build(),
        )
    }

    private fun normalize(number: String): String {
        var digits = number.filter(Char::isDigit)
        if (digits.startsWith("00")) digits = digits.drop(2)
        if ((digits.length == 10 || digits.length == 11) && !digits.startsWith("55")) {
            digits = "55$digits"
        }
        return digits
    }

    private fun normalizedNotificationId(number: String): Int =
        normalize(number).hashCode() and 0x7fffffff
}

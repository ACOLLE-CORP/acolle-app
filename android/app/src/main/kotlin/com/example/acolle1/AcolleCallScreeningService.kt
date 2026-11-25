package com.example.acolle1

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import kotlin.concurrent.thread

internal const val CALL_ALERT_CHANNEL = "acolle_call_alerts_v2"
internal const val CALL_ALERT_TAG = "AcolleCallerId"
internal const val CALLER_ID_PREFS = "acolle_caller_id"
internal const val SUSPECT_NUMBERS_KEY = "suspect_numbers"
internal const val LISTA_CONFIRMADA_EM = "lista_confirmada_em"

class AcolleCallScreeningService : CallScreeningService() {
    override fun onScreenCall(callDetails: Call.Details) {
        if (Build.VERSION.SDK_INT >= 29 && callDetails.callDirection != Call.Details.DIRECTION_INCOMING) return
        // A consulta é informativa. Libere a chamada dentro do prazo do Android.
        respondToCall(callDetails, CallResponse.Builder().build())

        val handle = callDetails.handle
        val number = handle?.schemeSpecificPart.orEmpty()
        if (handle?.scheme != "tel" || PhoneReputation.normalize(number).isEmpty()) return
        Log.i(CALL_ALERT_TAG, "Chamada telefônica recebida")
        thread(name = "acolle-verificar-chamada") { verifyCall(number) }
    }

    private fun verifyCall(number: String) {
        val id = PhoneReputation.normalize(number).hashCode() and Int.MAX_VALUE
        if (contatoSalvo(number)) {
            avisarChamada(id, "Contato salvo", number)
            return
        }
        if (numeroSuspeitoNoCache(number)) {
            showResult(id, number, CallAlertStatus.SUSPECT)
            return
        }

        CallerAlertOverlay.show(this, number, CallAlertStatus.CHECKING)
        avisarChamada(id, "Verificando número…", number)
        showResult(id, number, PhoneReputation.avaliarNumero(this, number))
    }

    private fun showResult(id: Int, number: String, status: CallAlertStatus) {
        CallerAlertOverlay.show(this, number, status)

        val details = PendingIntent.getActivity(
            this,
            id,
            Intent(this, IncomingCallAlertActivity::class.java).apply {
                putExtra(IncomingCallAlertActivity.EXTRA_NUMBER, number)
                putExtra(IncomingCallAlertActivity.EXTRA_STATUS, status.name)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        avisarChamada(id, status.titulo, "$number · ${status.descricao}", details)
    }
}

internal fun Context.numeroSuspeitoNoCache(numero: String): Boolean =
    getSharedPreferences(CALLER_ID_PREFS, Context.MODE_PRIVATE)
        .getStringSet(SUSPECT_NUMBERS_KEY, emptySet())
        .orEmpty()
        .contains(PhoneReputation.normalize(numero))

internal fun Context.contatoSalvo(numero: String): Boolean {
    if (checkSelfPermission(android.Manifest.permission.READ_CONTACTS) !=
        android.content.pm.PackageManager.PERMISSION_GRANTED) return false
    val lookup = android.provider.ContactsContract.PhoneLookup.CONTENT_FILTER_URI
    val uri = android.net.Uri.withAppendedPath(lookup, android.net.Uri.encode(numero))
    return try {
        contentResolver.query(uri, arrayOf("_id"), null, null, null)
            ?.use { it.moveToFirst() } == true
    } catch (_: SecurityException) {
        false
    }
}

internal fun Context.criarCanalDeChamadas() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(
                CALL_ALERT_CHANNEL,
                "Alertas de chamadas",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Avisa sobre a verificação de números em chamadas recebidas"
                enableVibration(true)
            },
        )
    }
}

internal fun Context.notificacoesDeChamadasAtivas(): Boolean {
    if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) return false
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
    val canal = getSystemService(NotificationManager::class.java)
        .getNotificationChannel(CALL_ALERT_CHANNEL)
    return canal?.importance != NotificationManager.IMPORTANCE_NONE
}

internal fun Context.avisarChamada(
    id: Int,
    titulo: String,
    texto: String,
    detalhes: PendingIntent? = null,
) {
    criarCanalDeChamadas()
    if (!notificacoesDeChamadasAtivas()) {
        Log.w(CALL_ALERT_TAG, "Notificações do Acolle ou canal de chamadas desativado")
        return
    }
    val aviso = NotificationCompat.Builder(this, CALL_ALERT_CHANNEL)
        .setSmallIcon(R.drawable.ic_acolle_notification)
        .setContentTitle(titulo)
        .setContentText(texto)
        .setStyle(NotificationCompat.BigTextStyle().bigText(texto))
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .setCategory(NotificationCompat.CATEGORY_STATUS)
        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        .setAutoCancel(true)
        .setTimeoutAfter(if (detalhes == null) 60_000 else 0)
        .setContentIntent(detalhes)
        .build()
    try {
        getSystemService(NotificationManager::class.java).notify(id, aviso)
    } catch (error: SecurityException) {
        Log.w(CALL_ALERT_TAG, "Android bloqueou a notificação de chamada", error)
    }
}

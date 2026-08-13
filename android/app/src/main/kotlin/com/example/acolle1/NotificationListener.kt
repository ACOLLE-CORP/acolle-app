package com.example.acolle1

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationListener : NotificationListenerService() {

    // Pacotes que queremos monitorar (WhatsApp, SMS padrão, Gmail)
    private val pacotesMonitorados = setOf(
        "com.whatsapp",
        "com.google.android.apps.messaging", // SMS padrão do Android
        "com.android.mms",
        "com.google.android.gm" // Gmail, opcional
    )

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        if (sbn.packageName !in pacotesMonitorados) return

        val extras = sbn.notification.extras
        val titulo = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val texto = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        if (texto.isBlank()) return

        // Envia o conteúdo para o MainActivity via broadcast local
        val intent = Intent("com.seudominio.acolle.NOVA_NOTIFICACAO")
        intent.putExtra("pacote", sbn.packageName)
        intent.putExtra("titulo", titulo)
        intent.putExtra("texto", texto)
        sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
        // Não precisa fazer nada aqui por enquanto
    }
}
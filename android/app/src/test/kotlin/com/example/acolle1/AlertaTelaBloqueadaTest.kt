package com.example.acolle1

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.PowerManager
import android.os.Process
import android.service.notification.StatusBarNotification
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class AlertaTelaBloqueadaTest {
    @Test
    fun mensagemDeAltoRiscoGeraAlertaPersistenteComVersaoPublicaGenerica() {
        val controller = Robolectric.buildService(NotificationListener::class.java).create()
        try {
            val service = controller.get()
            val keyguard = service.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            shadowOf(keyguard).setKeyguardLocked(true)
            val energia = service.getSystemService(PowerManager::class.java)
            shadowOf(energia).setIsInteractive(false)
            assertTrue(keyguard.isKeyguardLocked)
            assertFalse(energia.isInteractive)
            val agora = System.currentTimeMillis()
            val mensagem = Notification.Builder(service, "conversa")
                .setCategory(Notification.CATEGORY_MESSAGE)
                .setContentTitle("Contato de teste")
                .setContentText("Mãe, preciso de um Pix urgente agora.")
                .setWhen(agora - 180_000)
                .build()
            val evento = StatusBarNotification("com.whatsapp", "com.whatsapp", 7, null,
                Process.myUid(), 0, 0, mensagem, Process.myUserHandle(), agora)
            service.onNotificationPosted(evento)
            val manager = service.getSystemService(NotificationManager::class.java)
            val aviso = manager.activeNotifications.single { it.id == MESSAGE_ALERT_ID }.notification
            assertEquals(0L, aviso.timeoutAfter)
            assertEquals(Notification.VISIBILITY_PRIVATE, aviso.visibility)
            assertEquals("Pare e confira: sinais de golpe", aviso.extras.getString(Notification.EXTRA_TITLE))
            assertEquals("Desbloqueie para conferir a orientação.",
                aviso.publicVersion.extras.getString(Notification.EXTRA_TEXT))
            assertNotNull(aviso.contentIntent)
        } finally {
            controller.destroy()
        }
    }
}

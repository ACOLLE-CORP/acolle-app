package com.example.acolle1

import android.app.Activity
import android.app.NotificationManager
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** Orientação aberta pelo usuário; não interrompe outros aplicativos sozinha. */
class MessageAlertActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        getSystemService(NotificationManager::class.java).cancel(9100)
        val density = resources.displayMetrics.density
        fun dp(n: Int) = (n * density).toInt()
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(32), dp(24), dp(32))
            setBackgroundColor(Color.WHITE)
        }
        fun label(value: String, size: Float) {
            column.addView(TextView(this).apply {
                text = value
                textSize = size
                setTextColor(Color.rgb(42, 27, 93))
                setPadding(0, 0, 0, dp(22))
            })
        }
        fun action(value: String, callback: () -> Unit) {
            column.addView(Button(this).apply {
                text = value
                textSize = 20f
                isAllCaps = false
                minHeight = dp(60)
                setPadding(dp(12), dp(16), dp(12), dp(16))
                setOnClickListener { callback() }
            }, LinearLayout.LayoutParams(-1, -2))
        }
        label("Acolle • ${intent.getStringExtra("origem") ?: "Mensagem recebida"}", 18f)
        label(if (intent.getBooleanExtra("alto", false))
            "Pare um instante. Esta mensagem tem sinais de golpe."
            else "Vamos conferir esta mensagem com cuidado.", 28f)
        label("Por que este aviso apareceu?", 22f)
        label("O Acolle analisou uma notificação de mensagem recebida e encontrou possíveis sinais de golpe. Isso não confirma uma fraude.", 20f)
        label(intent.getStringExtra("recomendacao")
            ?: "Antes de responder ou pagar, fale com alguém de confiança por um telefone que você já conhece.", 22f)
        action("Pedir ajuda") {
            startActivity(Intent(this, MainActivity::class.java).apply {
                putExtra(FloatingBubbleService.EXTRA_ROTA, "ajuda")
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            })
            finish()
        }
        action("Entendi, fechar") { finish() }
        setContentView(ScrollView(this).apply { addView(column) })
    }
}

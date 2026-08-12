package com.example.acolle1

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView

object CallerAlertOverlay {
    private var currentView: LinearLayout? = null
    private val handler = Handler(Looper.getMainLooper())

    fun show(context: Context, number: String, suspect: Boolean?): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !Settings.canDrawOverlays(context)) return false

        handler.post {
            val manager = context.getSystemService(WindowManager::class.java)
            currentView?.let { runCatching { manager.removeView(it) } }

            val density = context.resources.displayMetrics.density
            fun dp(value: Int) = (value * density).toInt()
            fun rounded(color: Int, radius: Float) = GradientDrawable().apply {
                setColor(color)
                cornerRadius = radius * density
                setStroke(dp(2), when (suspect) {
                    true -> 0xFFFF981F.toInt()
                    false -> 0xFF5A49D6.toInt()
                    null -> 0xFF1976D2.toInt()
                })
            }

            val card = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(20), dp(16), dp(12), dp(16))
                background = rounded(Color.WHITE, 20f)
                elevation = dp(14).toFloat()
            }

            val header = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }
            val title = TextView(context).apply {
                text = when (suspect) {
                    true -> "⚠ POSSÍVEL GOLPE"
                    false -> "✓ SEM DENÚNCIAS ENCONTRADAS"
                    null -> "⌛ VERIFICANDO NÚMERO..."
                }
                textSize = 20f
                setTextColor(when (suspect) {
                    true -> 0xFFD35400.toInt()
                    false -> 0xFF2E7D32.toInt()
                    null -> 0xFF1565C0.toInt()
                })
                setTypeface(typeface, Typeface.BOLD)
            }
            header.addView(title, LinearLayout.LayoutParams(0, -2, 1f))
            val close = ImageButton(context).apply {
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                setBackgroundColor(Color.TRANSPARENT)
                contentDescription = "Fechar alerta"
                setOnClickListener { hide(context) }
            }
            header.addView(close, LinearLayout.LayoutParams(dp(48), dp(48)))
            card.addView(header)

            card.addView(TextView(context).apply {
                text = number
                textSize = 22f
                setTextColor(0xFF302268.toInt())
                setTypeface(typeface, Typeface.BOLD)
            })
            card.addView(TextView(context).apply {
                text = when (suspect) {
                    true -> "Número denunciado por outros usuários. Não informe senhas ou códigos."
                    false -> "Nenhuma denúncia encontrada. Isso não garante que a chamada seja segura."
                    null -> "Aguarde um instante enquanto o Acolle consulta a base de denúncias."
                }
                textSize = 15f
                setTextColor(0xFF55505F.toInt())
                setPadding(0, dp(6), 0, 0)
            })

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                x = 0
                // O banner de chamada do Android/MIUI ocupa o topo e sempre
                // tem prioridade sobre overlays. Posicionamos o alerta abaixo
                // dos botões Atender/Recusar para todo o conteúdo permanecer
                // legível, especialmente para pessoas idosas.
                y = dp(155)
            }

            runCatching {
                manager.addView(card, params)
                currentView = card
                handler.postDelayed({ hide(context) }, 30_000)
            }
        }
        return true
    }

    fun hide(context: Context) {
        handler.post {
            val manager = context.getSystemService(WindowManager::class.java)
            currentView?.let { runCatching { manager.removeView(it) } }
            currentView = null
        }
    }
}

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
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView

internal enum class CallAlertStatus(val chave: String, val titulo: String, val descricao: String) {
    CHECKING("verificando", "Verificando número…", "Aguarde enquanto o Acolle consulta a base de denúncias."),
    SUSPECT("suspeita", "Possível chamada de golpe", "Número denunciado. Não informe senhas ou códigos."),
    CLEAR("sem_denuncias", "Nenhuma denúncia encontrada", "A ausência de denúncias não garante que a chamada seja segura."),
    LOCAL_ONLY("sem_registro_local", "Sem registro na lista do Acolle", "A consulta externa está indisponível. Apenas a lista sincronizada do Acolle foi conferida."),
    INCOMPLETE("numero_incompleto", "Número incompleto", "O telefone recebido não tem dígitos suficientes para uma consulta ou está em formato inválido."),
    UNAVAILABLE("indisponivel", "Consulta indisponível", "Não foi possível consultar a base de denúncias neste momento.");
}

internal object CallerAlertOverlay {
    private var currentView: LinearLayout? = null
    private val handler = Handler(Looper.getMainLooper())

    fun show(context: Context, number: String, status: CallAlertStatus) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !Settings.canDrawOverlays(context)) return

        handler.post {
            val manager = context.getSystemService(WindowManager::class.java)
            currentView?.let { hide(it) }

            val density = context.resources.displayMetrics.density
            fun dp(value: Int) = (value * density).toInt()
            fun rounded(color: Int, radius: Float) = GradientDrawable().apply {
                setColor(color)
                cornerRadius = radius * density
                setStroke(dp(2), when (status) {
                    CallAlertStatus.SUSPECT -> 0xFFFF981F.toInt()
                    CallAlertStatus.CLEAR -> 0xFF5A49D6.toInt()
                    else -> 0xFF1976D2.toInt()
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
                text = when (status) {
                    CallAlertStatus.SUSPECT -> "⚠ POSSÍVEL GOLPE"
                    CallAlertStatus.CLEAR -> "✓ SEM DENÚNCIAS ENCONTRADAS"
                    CallAlertStatus.CHECKING -> "⌛ VERIFICANDO NÚMERO..."
                    else -> status.titulo
                }
                textSize = 20f
                setTextColor(when (status) {
                    CallAlertStatus.SUSPECT -> 0xFFD35400.toInt()
                    CallAlertStatus.CLEAR -> 0xFF2E7D32.toInt()
                    else -> 0xFF1565C0.toInt()
                })
                setTypeface(typeface, Typeface.BOLD)
            }
            header.addView(title, LinearLayout.LayoutParams(0, -2, 1f))
            val close = ImageButton(context).apply {
                setImageResource(R.drawable.ic_close_rounded)
                setColorFilter(0xFF2A1B5D.toInt())
                background = rounded(0xFFF1EEFF.toInt(), 24f)
                setPadding(dp(12), dp(12), dp(12), dp(12))
                contentDescription = "Fechar alerta"
                setOnClickListener { hide(card) }
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
                text = status.descricao
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
                handler.postDelayed({ hide(card) }, 30_000)
            }.onFailure {
                Log.w(CALL_ALERT_TAG, "Android bloqueou a sobreposição da chamada", it)
            }
        }
    }

    private fun hide(view: LinearLayout) {
        if (currentView !== view) return
        val manager = view.context.getSystemService(WindowManager::class.java)
        runCatching { manager.removeView(view) }
        currentView = null
    }
}

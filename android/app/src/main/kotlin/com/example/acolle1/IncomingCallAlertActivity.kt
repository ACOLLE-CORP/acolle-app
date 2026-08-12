package com.example.acolle1

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.Space
import android.widget.TextView

class IncomingCallAlertActivity : Activity() {
    companion object {
        const val EXTRA_NUMBER = "number"
        const val EXTRA_SUSPECT = "suspect"
        private const val PURPLE = 0xFF302268.toInt()
        private const val ACCENT = 0xFF6C4CE6.toInt()
        private const val ORANGE = 0xFFFF981F.toInt()
        private const val GREEN = 0xFF2E7D32.toInt()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
        )
        window.attributes = window.attributes.apply { dimAmount = 0.32f }
        render(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        render(intent)
    }

    private fun render(source: Intent) {
        val number = source.getStringExtra(EXTRA_NUMBER).orEmpty().ifBlank { "Número oculto" }
        val suspect = source.getBooleanExtra(EXTRA_SUSPECT, false)
        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(22), dp(32), dp(22), dp(32))
            setBackgroundColor(0x18000000)
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(22), dp(26), dp(22), dp(22))
            background = rounded(Color.WHITE, 28f)
            elevation = dp(14).toFloat()
        }
        root.addView(
            card,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        card.addView(label("CHAMADA RECEBIDA", 12f, ACCENT, true).apply {
            letterSpacing = 0.14f
        })
        card.addView(space(18))
        card.addView(label(if (suspect) "!" else "✓", 42f, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            background = rounded(if (suspect) ORANGE else ACCENT, 44f)
            elevation = dp(8).toFloat()
        }, LinearLayout.LayoutParams(dp(88), dp(88)))
        card.addView(space(18))
        card.addView(label("Número desconhecido", 25f, PURPLE, true))
        card.addView(space(6))
        card.addView(label(number, 17f, 0xFF77738A.toInt(), false))
        card.addView(space(18))

        val warningColor = if (suspect) ORANGE else GREEN
        val warningText = if (suspect) {
            "⚠  Número suspeito detectado"
        } else {
            "✓  Nenhuma denúncia encontrada"
        }
        card.addView(label(warningText, 17f, PURPLE, true).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = rounded(withAlpha(warningColor, 0x25), 14f)
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(58)))
        card.addView(space(10))
        card.addView(label(
            if (suspect) "Não informe senhas, códigos ou dados bancários."
            else "A ausência de denúncias não garante que a ligação seja segura.",
            14f,
            0xFF696477.toInt(),
            false,
        ).apply { gravity = Gravity.CENTER })
        card.addView(space(28))

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        actions.addView(actionButton("Voltar à chamada", ORANGE) { finish() })
        actions.addView(space(12, horizontal = true))
        actions.addView(actionButton("Abrir Acolle", ACCENT) {
            startActivity(Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            })
            finish()
        })
        card.addView(actions)
        setContentView(root)
    }

    private fun label(text: String, size: Float, color: Int, bold: Boolean) =
        TextView(this).apply {
            this.text = text
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER
            if (bold) setTypeface(typeface, Typeface.BOLD)
        }

    private fun actionButton(text: String, color: Int, action: () -> Unit) =
        Button(this).apply {
            this.text = text
            textSize = 14f
            setTextColor(Color.WHITE)
            isAllCaps = false
            background = rounded(color, 16f)
            setPadding(18, 0, 18, 0)
            setOnClickListener { action() }
            layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
        }

    private fun rounded(color: Int, radiusDp: Float) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radiusDp * resources.displayMetrics.density
    }

    private fun withAlpha(color: Int, alpha: Int): Int =
        Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))

    private fun space(size: Int, horizontal: Boolean = false): Space = Space(this).apply {
        layoutParams = if (horizontal) {
            LinearLayout.LayoutParams(dp(size), 1)
        } else {
            LinearLayout.LayoutParams(1, dp(size))
        }
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}

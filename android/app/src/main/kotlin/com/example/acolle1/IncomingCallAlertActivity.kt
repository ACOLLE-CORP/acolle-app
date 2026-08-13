package com.example.acolle1

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.Space
import android.widget.TextView
import android.widget.Toast
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import kotlin.concurrent.thread

class IncomingCallAlertActivity : Activity() {
    companion object {
        const val EXTRA_NUMBER = "number"
        const val EXTRA_SUSPECT = "suspect"
        const val EXTRA_ANALYZE = "analyze"
        private const val WORKER_URL =
            "https://acolle-spam-check.acolle-corp.workers.dev/verificar"
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
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(source: Intent) {
        val number = source.getStringExtra(EXTRA_NUMBER).orEmpty().ifBlank { "Número oculto" }
        if (source.getBooleanExtra(EXTRA_ANALYZE, false)) {
            render(number, null)
            analyzeNumber(number)
        } else {
            render(number, source.getBooleanExtra(EXTRA_SUSPECT, false))
        }
    }

    private fun analyzeNumber(number: String) {
        thread(name = "acolle-debug-spam-check") {
            val analysisStartedAt = SystemClock.elapsedRealtime()
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
                val remainingDisplayTime =
                    2_000L - (SystemClock.elapsedRealtime() - analysisStartedAt)
                if (remainingDisplayTime > 0) Thread.sleep(remainingDisplayTime)
                runOnUiThread { if (!isFinishing) render(number, suspect) }
            } catch (_: Exception) {
                runOnUiThread { if (!isFinishing) renderError(number) }
            }
        }
    }

    private fun render(number: String, suspect: Boolean?) {
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
        val statusIcon = when (suspect) {
            true -> "!"
            false -> "✓"
            null -> "…"
        }
        val statusColor = when (suspect) {
            true -> PURPLE
            false -> ACCENT
            null -> 0xFF1976D2.toInt()
        }
        card.addView(label(statusIcon, 42f, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            background = rounded(statusColor, 44f)
            elevation = dp(8).toFloat()
        }, LinearLayout.LayoutParams(dp(88), dp(88)))
        card.addView(space(18))
        card.addView(label("Número desconhecido", 25f, ORANGE, true))
        card.addView(space(6))
        card.addView(label(number, 17f, 0xFF77738A.toInt(), false))
        card.addView(space(18))

        val warningColor = when (suspect) {
            true -> PURPLE
            false -> GREEN
            null -> 0xFF1976D2.toInt()
        }
        val warningText = when (suspect) {
            true -> "⚠  Número suspeito detectado"
            false -> "✓  Nenhuma denúncia encontrada"
            null -> "⌛  Analisando o número..."
        }
        card.addView(label(warningText, 17f, PURPLE, true).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = rounded(withAlpha(warningColor, 0x25), 14f)
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(58)))
        card.addView(space(10))
        card.addView(label(
            when (suspect) {
                true -> "Não informe senhas, códigos ou dados bancários."
                false -> "A ausência de denúncias não garante que a ligação seja segura."
                null -> "Consultando a base de denúncias. Aguarde um instante."
            },
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

    private fun renderError(number: String) {
        render(number, null)
        Toast.makeText(
            this,
            "Não foi possível verificar. Tente novamente em alguns segundos.",
            Toast.LENGTH_LONG,
        ).show()
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

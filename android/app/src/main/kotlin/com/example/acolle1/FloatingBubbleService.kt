package com.example.acolle1

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class FloatingBubbleService : Service() {

    companion object {
        const val CANAL_SERVICO_ID = "acolle_botao_flutuante"
        const val ID_NOTIFICACAO_SERVICO = 9001

        // Extra usado para dizer ao Flutter qual tela abrir ao tocar
        // em uma opção do menu.
        const val EXTRA_ROTA = "acolle_rota"
    }

    private lateinit var windowManager: WindowManager
    private var bolinhaView: View? = null
    private var menuView: View? = null
    private var menuAberto = false

    private val roxo = Color.parseColor("#773FD1")

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        iniciarComoForegroundService()
        criarBolinha()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // START_STICKY: se o sistema matar o serviço por falta de memória,
        // ele tenta recriar automaticamente.
        return START_STICKY
    }

    // ============================================================
    // Notificação obrigatória de foreground service
    // ============================================================

    private fun iniciarComoForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CANAL_SERVICO_ID,
                    "Botão de proteção ativo",
                    NotificationManager.IMPORTANCE_MIN, // não faz barulho nem vibra
                ).apply {
                    description = "Mantém o botão flutuante de proteção do Acolle na tela"
                },
            )
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notificacao = NotificationCompat.Builder(this, CANAL_SERVICO_ID)
            .setSmallIcon(R.mipmap.icon)
            .setContentTitle("Acolle protegendo você")
            .setContentText("Toque para abrir o app")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        startForeground(ID_NOTIFICACAO_SERVICO, notificacao)
    }

    // ============================================================
    // Bolinha flutuante (arrastável, com toque = abre o menu)
    // ============================================================

    private fun criarBolinha() {
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val bolinha = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_dialog_alert)
            setColorFilter(Color.WHITE)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(roxo)
            }
            setPadding(dp(14), dp(14), dp(14), dp(14))
            elevation = dp(8).toFloat()
        }

        val tamanho = dp(56)
        val params = WindowManager.LayoutParams(
            tamanho, tamanho,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dp(16)
            y = dp(300)
        }

        // Arrastar a bolinha pela tela, sem abrir o menu sem querer.
        var xInicial = 0
        var yInicial = 0
        var xToqueInicial = 0f
        var yToqueInicial = 0f
        var houveArrasto = false

        bolinha.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    xInicial = params.x
                    yInicial = params.y
                    xToqueInicial = event.rawX
                    yToqueInicial = event.rawY
                    houveArrasto = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - xToqueInicial).toInt()
                    val dy = (event.rawY - yToqueInicial).toInt()
                    if (abs(dx) > 10 || abs(dy) > 10) houveArrasto = true
                    params.x = xInicial + dx
                    params.y = yInicial + dy
                    windowManager.updateViewLayout(bolinha, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!houveArrasto) alternarMenu(params)
                    true
                }
                else -> false
            }
        }

        windowManager.addView(bolinha, params)
        bolinhaView = bolinha
    }

    // ============================================================
    // Menu expansível (as opções do seu print)
    // ============================================================

    private fun alternarMenu(paramsBolinha: WindowManager.LayoutParams) {
        if (menuAberto) {
            fecharMenu()
            return
        }

        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val menu = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(4), dp(4), dp(4), dp(4))
        }

        menu.addView(itemMenu("Analisar esta tela", android.R.drawable.ic_menu_camera) {
            abrirTelaFlutter("analisar")
        })
        menu.addView(itemMenu("Verificar link", android.R.drawable.ic_menu_share) {
            abrirTelaFlutter("verificar_link")
        })
        menu.addView(itemMenu("Meus alertas", android.R.drawable.ic_dialog_alert) {
            abrirTelaFlutter("alertas")
        })
        menu.addView(itemMenu("Falar com o Acolle", android.R.drawable.ic_menu_send) {
            abrirTelaFlutter("chat")
        })
        menu.addView(itemMenuFechar())

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = paramsBolinha.x
            y = paramsBolinha.y + dp(64)
        }

        windowManager.addView(menu, params)
        menuView = menu
        menuAberto = true
    }

    private fun itemMenu(texto: String, icone: Int, acao: () -> Unit): View {
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(12), dp(20), dp(12))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(24).toFloat()
            }
            elevation = dp(4).toFloat()
            (layoutParams as? LinearLayout.LayoutParams)?.setMargins(0, 0, 0, dp(8))
            setOnClickListener {
                fecharMenu()
                acao()
            }
        }

        val bolaIcone = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(roxo)
            }
        }
        val img = ImageView(this).apply {
            setImageResource(icone)
            setColorFilter(Color.WHITE)
            setPadding(dp(8), dp(8), dp(8), dp(8))
        }
        bolaIcone.addView(img, FrameLayout.LayoutParams(dp(36), dp(36)))
        container.addView(bolaIcone, LinearLayout.LayoutParams(dp(36), dp(36)))

        container.addView(TextView(this).apply {
            text = texto
            textSize = 15f
            setTextColor(Color.parseColor("#333333"))
            setPadding(dp(12), 0, 0, 0)
            typeface = Typeface.DEFAULT_BOLD
        })

        // Envolve num LinearLayout externo para aplicar a margem inferior.
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { setMargins(0, 0, 0, dp(8)) }
            addView(container)
        }
    }

    private fun itemMenuFechar(): View {
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(16), dp(10), dp(16), dp(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(roxo)
            }
            setOnClickListener { fecharMenu() }
            addView(ImageView(this@FloatingBubbleService).apply {
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                setColorFilter(Color.WHITE)
            }, LinearLayout.LayoutParams(dp(24), dp(24)))
        }
    }

    private fun fecharMenu() {
        menuView?.let { runCatching { windowManager.removeView(it) } }
        menuView = null
        menuAberto = false
    }

    // ============================================================
    // Abrir uma tela do Flutter a partir do botão flutuante
    // ============================================================

    private fun abrirTelaFlutter(rota: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            putExtra(EXTRA_ROTA, rota)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        bolinhaView?.let { runCatching { windowManager.removeView(it) } }
        fecharMenu()
    }
}
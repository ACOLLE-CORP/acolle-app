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

        @Volatile
        var emExecucao: Boolean = false
            private set
    }

    private lateinit var windowManager: WindowManager
    private var bolinhaView: View? = null
    private var menuView: View? = null
    private var menuParams: WindowManager.LayoutParams? = null
    private var menuAberto = false

    private val roxo = Color.parseColor("#6D59F4")
    private val roxoEscuro = Color.parseColor("#2A1B5D")
    private val fundoSuave = Color.parseColor("#FBFAFF")

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        emExecucao = true
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
            .setSmallIcon(R.drawable.ic_acolle_notification)
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
            setImageResource(R.drawable.acolle_collin)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            contentDescription = "Abrir proteção rápida do Acolle"
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(fundoSuave)
                setStroke(dp(3), roxo)
            }
            setPadding(dp(5), dp(5), dp(5), dp(5))
            elevation = dp(8).toFloat()
        }

        val tamanho = dp(64)
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
                    params.x = (xInicial + dx).coerceIn(
                        dp(8),
                        resources.displayMetrics.widthPixels - tamanho - dp(8),
                    )
                    params.y = (yInicial + dy).coerceIn(
                        dp(32),
                        resources.displayMetrics.heightPixels - tamanho - dp(32),
                    )
                    windowManager.updateViewLayout(bolinha, params)

                    if (menuAberto) {
                        atualizarPosicaoMenu(params)
                    }

                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!houveArrasto) {
                        alternarMenu(params)
                    } else {
                        params.x = if (
                            params.x + tamanho / 2 < resources.displayMetrics.widthPixels / 2
                        ) {
                            dp(12)
                        } else {
                            resources.displayMetrics.widthPixels - tamanho - dp(12)
                        }
                        windowManager.updateViewLayout(bolinha, params)
                        if (menuAberto) {
                            atualizarPosicaoMenu(params)
                        }
                    }
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
            setPadding(dp(8), dp(8), dp(8), dp(8))
            background = GradientDrawable().apply {
                setColor(fundoSuave)
                cornerRadius = dp(28).toFloat()
                setStroke(dp(1), Color.parseColor("#E1DCEF"))
            }
            elevation = dp(10).toFloat()
        }

        menu.addView(itemMenu("Analisar esta tela", "📷") {

            val intent =
                Intent(
                    this,
                    ScreenCapturePermissionActivity::class.java
                ).apply {

                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK
                    )
                }

            startActivity(intent)
        })
        menu.addView(itemMenu("Verificar link", "🔗") {
            abrirTelaFlutter("verificar_link")
        })
        menu.addView(itemMenu("Meus alertas", "🔔") {
            abrirTelaFlutter("alertas")
        })
        menu.addView(itemMenu("Pedir ajuda", "🤝") {
            abrirTelaFlutter("ajuda")
        })
        menu.addView(itemMenuFechar())

        val larguraMenu = dp(280)
        val alturaEstimada = dp(324)
        val larguraTela = resources.displayMetrics.widthPixels
        val alturaTela = resources.displayMetrics.heightPixels
        val params = WindowManager.LayoutParams(
            larguraMenu,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = paramsBolinha.x.coerceIn(dp(12), larguraTela - larguraMenu - dp(12))
            y = if (paramsBolinha.y > alturaTela / 2) {
                (paramsBolinha.y - alturaEstimada).coerceAtLeast(dp(32))
            } else {
                (paramsBolinha.y + dp(72)).coerceAtMost(alturaTela - alturaEstimada - dp(24))
            }
        }

        windowManager.addView(menu, params)
        menuView = menu
        menuParams = params
        menuAberto = true
    }

    private fun atualizarPosicaoMenu(
        paramsBolinha: WindowManager.LayoutParams
    ) {
        if (!menuAberto) return

        val menu = menuView ?: return
        val paramsMenu = menuParams ?: return

        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val larguraMenu = dp(280)
        val alturaEstimada = dp(324)

        val larguraTela = resources.displayMetrics.widthPixels
        val alturaTela = resources.displayMetrics.heightPixels

        paramsMenu.x = paramsBolinha.x.coerceIn(
            dp(12),
            larguraTela - larguraMenu - dp(12)
        )

        paramsMenu.y = if (paramsBolinha.y > alturaTela / 2) {

            (paramsBolinha.y - alturaEstimada)
                .coerceAtLeast(dp(32))

        } else {

            (paramsBolinha.y + dp(72))
                .coerceAtMost(
                    alturaTela - alturaEstimada - dp(24)
                )
        }

        runCatching {
            windowManager.updateViewLayout(
                menu,
                paramsMenu
            )
        }
    }


    private fun itemMenu(texto: String, simbolo: String, acao: () -> Unit): View {
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(10), dp(14), dp(10))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(18).toFloat()
            }
            isClickable = true
            isFocusable = true
            contentDescription = texto
            setOnClickListener {
                fecharMenu()
                acao()
            }
        }

        val bolaIcone = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#EDE9FF"))
            }
        }
        val img = TextView(this).apply {
            text = simbolo
            textSize = 21f
            gravity = Gravity.CENTER
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        bolaIcone.addView(img, FrameLayout.LayoutParams(dp(40), dp(40)))
        container.addView(bolaIcone, LinearLayout.LayoutParams(dp(40), dp(40)))

        container.addView(TextView(this).apply {
            text = texto
            textSize = 16f
            setTextColor(roxoEscuro)
            setPadding(dp(12), 0, 0, 0)
            typeface = Typeface.DEFAULT_BOLD
        }, LinearLayout.LayoutParams(
            0,
            LinearLayout.LayoutParams.WRAP_CONTENT,
            1f,
        ))

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
            setPadding(dp(16), dp(11), dp(16), dp(11))
            background = GradientDrawable().apply {
                setColor(roxo)
                cornerRadius = dp(18).toFloat()
            }
            contentDescription = "Fechar menu de proteção"
            setOnClickListener { fecharMenu() }
            addView(TextView(this@FloatingBubbleService).apply {
                text = "Fechar menu"
                textSize = 16f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                typeface = Typeface.DEFAULT_BOLD
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(28),
            ))
        }
    }

    private fun fecharMenu() {
        menuView?.let {
            runCatching {
                windowManager.removeView(it)
            }
        }

        menuView = null
        menuParams = null
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
        emExecucao = false
        bolinhaView?.let { runCatching { windowManager.removeView(it) } }
        fecharMenu()
    }
}

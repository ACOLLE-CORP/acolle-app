package com.example.acolle1

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.io.FileOutputStream

class ScreenCaptureService : Service() {

    companion object {
        private const val CHANNEL_ID = "acolle_screen_capture"
        private const val NOTIFICATION_ID = 9100

        const val PREFS_CAPTURE = "acolle_screen_capture"
        const val KEY_TEXTO_PENDENTE = "texto_pendente"

        // O primeiro frame do VirtualDisplay costuma vir preto/transparente.
        private const val MAX_TENTATIVAS_FRAME = 8
        private const val TIMEOUT_CAPTURA_MS = 7000L
    }

    private var tentativasFrame = 0
    private var capturaConcluida = false
    private var modoLink = false

    private val handler = Handler(Looper.getMainLooper())

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null

    private var encerrado = false
    private var processandoOcr = false

    private val projectionCallback =
        object : MediaProjection.Callback() {

            override fun onStop() {
                liberarRecursosCaptura()

                if (!processandoOcr) {
                    finalizarServico()
                }
            }
        }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        criarCanalNotificacao()
        iniciarForeground()

        modoLink =
            intent?.getStringExtra(
                ScreenCapturePermissionActivity.EXTRA_MODO
            ) == ScreenCapturePermissionActivity.MODO_LINK

        val resultCode =
            intent?.getIntExtra(
                ScreenCapturePermissionActivity.EXTRA_RESULT_CODE,
                Activity.RESULT_CANCELED
            ) ?: Activity.RESULT_CANCELED

        val resultData: Intent? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

                intent?.getParcelableExtra(
                    ScreenCapturePermissionActivity.EXTRA_RESULT_DATA,
                    Intent::class.java
                )

            } else {

                @Suppress("DEPRECATION")
                intent?.getParcelableExtra(
                    ScreenCapturePermissionActivity.EXTRA_RESULT_DATA
                )
            }

        if (
            resultCode != Activity.RESULT_OK ||
            resultData == null
        ) {
            finalizarServico()
            return START_NOT_STICKY
        }

        val manager =
            getSystemService(
                Context.MEDIA_PROJECTION_SERVICE
            ) as MediaProjectionManager

        mediaProjection =
            manager.getMediaProjection(
                resultCode,
                resultData
            )

        mediaProjection?.registerCallback(
            projectionCallback,
            handler
        )

        handler.postDelayed(
            {
                capturarTela()
            },
            800
        )

        return START_NOT_STICKY
    }

    private fun iniciarForeground() {

        val notification =
            NotificationCompat.Builder(
                this,
                CHANNEL_ID
            )
                .setSmallIcon(
                    R.drawable.ic_acolle_notification
                )
                .setContentTitle(
                    "Acolle analisando a tela"
                )
                .setContentText(
                    "Lendo o conteúdo para verificar possíveis riscos"
                )
                .setOngoing(true)
                .setPriority(
                    NotificationCompat.PRIORITY_LOW
                )
                .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )

        } else {

            startForeground(
                NOTIFICATION_ID,
                notification
            )
        }
    }

    private fun criarCanalNotificacao() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val manager =
                getSystemService(
                    NotificationManager::class.java
                )

            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    "Análise de tela",
                    NotificationManager.IMPORTANCE_LOW
                )

            manager.createNotificationChannel(
                channel
            )
        }
    }

    private fun capturarTela() {

        val metrics = resources.displayMetrics

        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        imageReader =
            ImageReader.newInstance(
                width,
                height,
                PixelFormat.RGBA_8888,
                2
            )

        imageReader?.setOnImageAvailableListener(
            { reader ->

                val image =
                    reader.acquireLatestImage()
                        ?: return@setOnImageAvailableListener

                var concluido = false

                try {

                    val plane = image.planes[0]
                    val buffer = plane.buffer

                    val pixelStride = plane.pixelStride
                    val rowStride = plane.rowStride

                    val rowPadding =
                        rowStride - pixelStride * width

                    val bitmapWidth =
                        width + rowPadding / pixelStride

                    val bitmap =
                        Bitmap.createBitmap(
                            bitmapWidth,
                            height,
                            Bitmap.Config.ARGB_8888
                        )

                    bitmap.copyPixelsFromBuffer(buffer)

                    // Alguns aparelhos entregam o canal alpha zerado; nesse caso
                    // a imagem inteira fica "invisível" para o OCR. Forçamos alpha
                    // opaco em todos os pixels e recortamos o padding de linha.
                    val pixels = IntArray(bitmapWidth * height)
                    bitmap.getPixels(pixels, 0, bitmapWidth, 0, 0, bitmapWidth, height)
                    bitmap.recycle()
                    val bitmapFinal =
                        Bitmap.createBitmap(
                            width,
                            height,
                            Bitmap.Config.ARGB_8888
                        )
                    val linha = IntArray(width)
                    for (y in 0 until height) {
                        val base = y * bitmapWidth
                        for (x in 0 until width) {
                            linha[x] = pixels[base + x] or 0xFF000000.toInt()
                        }
                        bitmapFinal.setPixels(linha, 0, width, 0, y, width, 1)
                    }

                    if (quadroEmBranco(bitmapFinal)) {

                        tentativasFrame++

                        Log.w(
                            "AcolleCapture",
                            "Frame em branco ($tentativasFrame/$MAX_TENTATIVAS_FRAME)"
                        )

                        bitmapFinal.recycle()

                        if (tentativasFrame < MAX_TENTATIVAS_FRAME) {
                            // Tela estática não gera frame novo sozinha:
                            // força um redesenho mudando a densidade em 1 dpi.
                            val dens =
                                density + (tentativasFrame % 2)
                            handler.postDelayed({
                                runCatching {
                                    virtualDisplay?.resize(
                                        width,
                                        height,
                                        dens
                                    )
                                }
                            }, 300)
                            return@setOnImageAvailableListener
                        }

                        concluido = true
                        Toast.makeText(
                            this,
                            "Esta tela não pode ser capturada " +
                                "(aparece em branco para o Acolle).",
                            Toast.LENGTH_LONG
                        ).show()
                        finalizarTudo()
                        return@setOnImageAvailableListener
                    }

                    concluido = true
                    capturaConcluida = true

                    processandoOcr = true

                    analisarTextoDaImagem(
                        bitmapFinal
                    )

                } catch (e: Exception) {

                    Log.e(
                        "AcolleCapture",
                        "Erro ao capturar tela",
                        e
                    )

                    concluido = true

                    Toast.makeText(
                        this,
                        "Não foi possível capturar esta tela.",
                        Toast.LENGTH_LONG
                    ).show()

                    finalizarTudo()

                } finally {

                    image.close()

                    if (concluido) {
                        encerrarSessaoCaptura()
                    }
                }

            },
            handler
        )

        // Se nenhum frame útil chegar, não deixa o serviço preso.
        handler.postDelayed({
            if (!capturaConcluida && !encerrado) {
                Log.w("AcolleCapture", "Timeout sem frame útil")
                Toast.makeText(
                    this,
                    "Não consegui capturar a tela. Tente de novo.",
                    Toast.LENGTH_LONG
                ).show()
                finalizarTudo()
            }
        }, TIMEOUT_CAPTURA_MS)

        virtualDisplay =
            mediaProjection?.createVirtualDisplay(
                "AcolleScreenCapture",
                width,
                height,
                density,
                DisplayManager
                    .VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null,
                handler
            )
    }

    /** True se a imagem é (quase) uma cor única: preta, branca ou vazia. */
    private fun quadroEmBranco(bitmap: Bitmap): Boolean {
        var min = 255
        var max = 0
        val passosX = 24
        val passosY = 48
        for (i in 0 until passosX) {
            for (j in 0 until passosY) {
                val px = bitmap.getPixel(
                    (i * (bitmap.width - 1)) / (passosX - 1),
                    (j * (bitmap.height - 1)) / (passosY - 1)
                )
                val lum =
                    (Color.red(px) * 3 + Color.green(px) * 6 +
                        Color.blue(px)) / 10
                if (lum < min) min = lum
                if (lum > max) max = lum
            }
        }
        return (max - min) < 6
    }

    private fun salvarCaptura(
        bitmap: Bitmap
    ): File {

        val arquivo =
            File(
                cacheDir,
                "acolle_capture_${System.currentTimeMillis()}.png"
            )

        FileOutputStream(
            arquivo
        ).use { output ->

            bitmap.compress(
                Bitmap.CompressFormat.PNG,
                100,
                output
            )
        }

        Log.i(
            "AcolleCapture",
            "Captura temporária: ${arquivo.absolutePath}"
        )

        return arquivo
    }

    private fun analisarTextoDaImagem(
        bitmap: Bitmap
    ) {

        val recognizer =
            TextRecognition.getClient(
                TextRecognizerOptions.DEFAULT_OPTIONS
            )

        val inputImage =
            InputImage.fromBitmap(bitmap, 0)

        Log.i(
            "AcolleOCR",
            "Analisando imagem ${bitmap.width}x${bitmap.height}"
        )

        recognizer
            .process(inputImage)
            .addOnSuccessListener { resultado ->

                val texto =
                    resultado.text.trim()

                if (texto.isBlank()) {

                    Log.w(
                        "AcolleOCR",
                        "OCR sem texto em ${bitmap.width}x${bitmap.height}"
                    )

                    Toast.makeText(
                        this,
                        "Não encontrei texto nesta tela " +
                            "(imagem ${bitmap.width}x${bitmap.height}).",
                        Toast.LENGTH_LONG
                    ).show()

                } else {

                    Log.i(
                        "AcolleOCR",
                        "Texto identificado com ${texto.length} caracteres"
                    )

                    getSharedPreferences(
                        PREFS_CAPTURE,
                        Context.MODE_PRIVATE
                    )
                        .edit()
                        .putString(
                            KEY_TEXTO_PENDENTE,
                            texto
                        )
                        .apply()

                    abrirAnaliseNoFlutter()
                }
            }
            .addOnFailureListener { e ->

                Log.e(
                    "AcolleOCR",
                    "Erro no reconhecimento de texto",
                    e
                )

                Toast.makeText(
                    this,
                    "Erro ao ler o texto: ${e.javaClass.simpleName}",
                    Toast.LENGTH_LONG
                ).show()
            }
            .addOnCompleteListener {

                recognizer.close()

                if (!bitmap.isRecycled) bitmap.recycle()

                processandoOcr = false

                finalizarServico()
            }
    }

    private fun abrirAnaliseNoFlutter() {

        val intent =
            Intent(
                this,
                MainActivity::class.java
            ).apply {

                putExtra(
                    FloatingBubbleService.EXTRA_ROTA,
                    if (modoLink) "verificar_link_tela" else "analisar_tela"
                )

                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }

        startActivity(intent)
    }

    private fun encerrarSessaoCaptura() {

        virtualDisplay?.release()
        virtualDisplay = null

        imageReader?.setOnImageAvailableListener(
            null,
            null
        )

        imageReader?.close()
        imageReader = null

        val projection =
            mediaProjection

        mediaProjection = null

        projection?.stop()
    }

    private fun liberarRecursosCaptura() {

        runCatching {
            virtualDisplay?.release()
        }

        virtualDisplay = null

        runCatching {
            imageReader?.close()
        }

        imageReader = null
    }

    private fun finalizarTudo() {

        processandoOcr = false

        val projection =
            mediaProjection

        mediaProjection = null

        runCatching {
            projection?.stop()
        }

        liberarRecursosCaptura()

        finalizarServico()
    }

    private fun finalizarServico() {

        if (encerrado) return

        encerrado = true

        stopForeground(
            STOP_FOREGROUND_REMOVE
        )

        stopSelf()
    }

    override fun onDestroy() {

        liberarRecursosCaptura()

        super.onDestroy()
    }
}
package com.example.acolle1

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
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
    }

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
            500
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

                    val bitmapFinal =
                        Bitmap.createBitmap(
                            bitmap,
                            0,
                            0,
                            width,
                            height
                        )

                    val arquivo =
                        salvarCaptura(bitmapFinal)

                    processandoOcr = true

                    analisarTextoDaImagem(
                        arquivo
                    )

                    bitmap.recycle()

                    if (bitmapFinal !== bitmap) {
                        bitmapFinal.recycle()
                    }

                } catch (e: Exception) {

                    Log.e(
                        "AcolleCapture",
                        "Erro ao capturar tela",
                        e
                    )

                    Toast.makeText(
                        this,
                        "Não foi possível capturar esta tela.",
                        Toast.LENGTH_LONG
                    ).show()

                    finalizarTudo()

                } finally {

                    image.close()

                    encerrarSessaoCaptura()
                }

            },
            handler
        )

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
        arquivo: File
    ) {

        val recognizer =
            TextRecognition.getClient(
                TextRecognizerOptions.DEFAULT_OPTIONS
            )

        val inputImage =
            try {

                InputImage.fromFilePath(
                    this,
                    Uri.fromFile(arquivo)
                )

            } catch (e: Exception) {

                Log.e(
                    "AcolleOCR",
                    "Erro ao preparar imagem",
                    e
                )

                arquivo.delete()

                recognizer.close()

                Toast.makeText(
                    this,
                    "Não foi possível ler a imagem.",
                    Toast.LENGTH_LONG
                ).show()

                processandoOcr = false
                finalizarServico()

                return
            }

        recognizer
            .process(inputImage)
            .addOnSuccessListener { resultado ->

                val texto =
                    resultado.text.trim()

                if (texto.isBlank()) {

                    Toast.makeText(
                        this,
                        "Não encontrei texto nesta tela.",
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
                    "Não foi possível ler o texto desta tela.",
                    Toast.LENGTH_LONG
                ).show()
            }
            .addOnCompleteListener {

                arquivo.delete()

                recognizer.close()

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
                    "analisar_tela"
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
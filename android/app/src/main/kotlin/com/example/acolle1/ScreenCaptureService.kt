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
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileOutputStream

class ScreenCaptureService : Service() {

    companion object {
        private const val CHANNEL_ID = "acolle_screen_capture"
        private const val NOTIFICATION_ID = 9100
    }

    private val handler = Handler(Looper.getMainLooper())

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null

    private var encerrado = false

    private val projectionCallback =
        object : MediaProjection.Callback() {

            override fun onStop() {
                limpar(false)
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

            stopSelf()
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

        // Pequena espera para a janela de autorização sumir.
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
                    "Capturando conteúdo para análise"
                )
                .setOngoing(true)
                .setPriority(
                    NotificationCompat.PRIORITY_LOW
                )
                .build()

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.Q
        ) {

            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo
                    .FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )

        } else {

            startForeground(
                NOTIFICATION_ID,
                notification
            )
        }
    }

    private fun criarCanalNotificacao() {

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O
        ) {

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

                    val pixelStride =
                        plane.pixelStride

                    val rowStride =
                        plane.rowStride

                    val rowPadding =
                        rowStride -
                            pixelStride * width

                    val bitmapWidth =
                        width +
                            rowPadding / pixelStride

                    val bitmap =
                        Bitmap.createBitmap(
                            bitmapWidth,
                            height,
                            Bitmap.Config.ARGB_8888
                        )

                    bitmap.copyPixelsFromBuffer(
                        buffer
                    )

                    val bitmapFinal =
                        Bitmap.createBitmap(
                            bitmap,
                            0,
                            0,
                            width,
                            height
                        )

                    salvarCaptura(bitmapFinal)

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

                } finally {

                    image.close()

                    limpar()
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

    private fun salvarCaptura(bitmap: Bitmap) {

        val arquivo =
            File(
                cacheDir,
                "acolle_capture_${System.currentTimeMillis()}.png"
            )

        FileOutputStream(arquivo).use { output ->

            bitmap.compress(
                Bitmap.CompressFormat.PNG,
                100,
                output
            )
        }

        Log.i(
            "AcolleCapture",
            "Captura salva em: ${arquivo.absolutePath}"
        )

        handler.post {

            Toast.makeText(
                this,
                "Captura realizada com sucesso",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    private fun limpar(
        pararProjection: Boolean = true
    ) {

        if (encerrado) return
        encerrado = true

        imageReader?.setOnImageAvailableListener(
            null,
            null
        )

        virtualDisplay?.release()
        virtualDisplay = null

        imageReader?.close()
        imageReader = null

        if (pararProjection) {
            mediaProjection?.stop()
        }

        mediaProjection = null

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        limpar()
        super.onDestroy()
    }
}
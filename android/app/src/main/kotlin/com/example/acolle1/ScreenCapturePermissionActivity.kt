package com.example.acolle1

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import androidx.core.content.ContextCompat

class ScreenCapturePermissionActivity : Activity() {

    companion object {
        const val EXTRA_RESULT_CODE = "screen_capture_result_code"
        const val EXTRA_RESULT_DATA = "screen_capture_result_data"

        private const val REQUEST_MEDIA_PROJECTION = 1001
    }

    private lateinit var projectionManager: MediaProjectionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE)
                    as MediaProjectionManager

        val captureIntent =
            projectionManager.createScreenCaptureIntent()

        @Suppress("DEPRECATION")
        startActivityForResult(
            captureIntent,
            REQUEST_MEDIA_PROJECTION
        )
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )

        if (requestCode != REQUEST_MEDIA_PROJECTION) {
            return
        }

        if (resultCode == RESULT_OK && data != null) {

            val serviceIntent =
                Intent(
                    this,
                    ScreenCaptureService::class.java
                ).apply {

                    putExtra(
                        EXTRA_RESULT_CODE,
                        resultCode
                    )

                    putExtra(
                        EXTRA_RESULT_DATA,
                        data
                    )
                }

            ContextCompat.startForegroundService(
                this,
                serviceIntent
            )
        }

        finish()
    }
}
package com.example.acolle1

import android.app.role.RoleManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "acolle/caller_id"
        private const val PREFS = "acolle_caller_id"
        private const val NUMBERS_KEY = "suspect_numbers"
        private const val ROLE_REQUEST_CODE = 7412
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestScreeningRole" -> requestScreeningRole(result)
                    "requestOverlayPermission" -> requestOverlayPermission(result)
                    "isScreeningRoleEnabled" -> result.success(isScreeningRoleEnabled())
                    "isOverlayPermissionEnabled" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this),
                    )
                    "syncSuspectNumbers" -> {
                        val numbers = call.argument<List<String>>("numbers").orEmpty()
                        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                            .edit()
                            .putStringSet(NUMBERS_KEY, numbers.toSet())
                            .apply()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isScreeningRoleEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val roleManager = getSystemService(RoleManager::class.java)
        return roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) &&
            roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun requestOverlayPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)) {
            result.success(true)
            return
        }
        startActivity(
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            ),
        )
        result.success(false)
    }

    private fun requestScreeningRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false)
            return
        }

        val roleManager = getSystemService(RoleManager::class.java)
        if (!roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(false)
            return
        }
        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(true)
            return
        }

        startActivityForResult(
            roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING),
            ROLE_REQUEST_CODE,
        )
        // A escolha é feita na tela do Android; uma próxima chamada confirma
        // novamente se o papel já foi concedido.
        result.success(false)
    }
}

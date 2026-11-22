package com.scutarilabs.scutari_core

import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ScutariCorePlugin - Offline Hardware Profiler */
class ScutariCorePlugin :
    FlutterPlugin,
    MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.scutarilabs.core/methods")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "inspectDevice" -> {
                val ctx = context
                if (ctx == null) {
                    result.error("CONTEXT_UNAVAILABLE", "Application context is null", null)
                    return
                }

                try {
                    val actManager = ctx.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                    val memInfo = ActivityManager.MemoryInfo()
                    actManager?.getMemoryInfo(memInfo)

                    val totalRamMb = (memInfo.totalMem / (1024L * 1024L)).toInt()
                    val availableRamMb = (memInfo.availMem / (1024L * 1024L)).toInt()
                    val cpuCores = Runtime.getRuntime().availableProcessors()

                    val delegates = mutableListOf<String>("cpu")

                    // NNAPI supported from Android 10 (API 29 - Android Q) onwards
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        delegates.add("nnapi")
                    }

                    // Check GPU acceleration capability (OpenGL ES 3.0+ or Vulkan)
                    val pm = ctx.packageManager
                    val hasVulkan = pm.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL)
                    val glVersion = actManager?.deviceConfigurationInfo?.reqGlEsVersion ?: 0
                    if (hasVulkan || glVersion >= 0x00030000) {
                        delegates.add("gpu")
                    }

                    val profileData = mapOf(
                        "totalRamMb" to totalRamMb,
                        "availableRamMb" to availableRamMb,
                        "cpuCores" to cpuCores,
                        "supportedDelegates" to delegates
                    )

                    result.success(profileData)
                } catch (e: Exception) {
                    result.error("PROFILING_ERROR", e.localizedMessage, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}


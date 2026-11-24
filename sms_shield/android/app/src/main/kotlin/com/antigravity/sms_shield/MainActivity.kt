package com.antigravity.sms_shield

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.sms_shield/llama_executorch"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isModelReady" -> {
                    // Check if quantized Llama 3.2 1B .pte model and tokenizer are present
                    val pteInFiles = File(filesDir, "llama1b_q4.pte").exists()
                    val pteInExternal = getExternalFilesDir(null)?.let { File(it, "llama1b_q4.pte").exists() } ?: false
                    var pteInAssets = false
                    try {
                        assets.open("models/llama1b_q4.pte").close()
                        pteInAssets = true
                    } catch (_: Exception) {
                        // Model not placed in assets yet
                    }

                    val isReady = pteInFiles || pteInExternal || pteInAssets
                    result.success(isReady)
                }

                "generate" -> {
                    val systemPrompt = call.argument<String>("systemPrompt") ?: ""
                    val userPrompt = call.argument<String>("userPrompt") ?: ""

                    // When native ExecuTorch .pte runner is loaded:
                    // ExecuTorchRunner.generate(systemPrompt, userPrompt)
                    // Currently falls back with explicit message if runner binary not yet linked
                    result.error(
                        "PTE_NOT_MOUNTED",
                        "llama1b_q4.pte not detected in app storage. Copy exported .pte file into device storage or assets.",
                        null
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

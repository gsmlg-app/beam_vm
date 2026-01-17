package io.beamvm.beam_vm_android

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

/**
 * Flutter plugin for embedding the Erlang/Elixir BEAM VM on Android.
 */
class BeamVmAndroidPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        init {
            System.loadLibrary("beam_vm")
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "io.beamvm/beam_vm")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val erlangPath = call.argument<String>("erlangPath")
                if (erlangPath == null) {
                    result.error("INVALID_ARGUMENT", "erlangPath is required", null)
                    return
                }
                initialize(erlangPath, result)
            }
            "shutdown" -> shutdown(result)
            "call" -> {
                val module = call.argument<String>("module")
                val function = call.argument<String>("function")
                val args = call.argument<String>("args")
                if (module == null || function == null || args == null) {
                    result.error("INVALID_ARGUMENT", "module, function, and args are required", null)
                    return
                }
                callFunction(module, function, args, result)
            }
            "send" -> {
                val processName = call.argument<String>("processName")
                val message = call.argument<String>("message")
                if (processName == null || message == null) {
                    result.error("INVALID_ARGUMENT", "processName and message are required", null)
                    return
                }
                sendMessage(processName, message, result)
            }
            "getOtpVersion" -> result.success(BeamVmNative.nativeGetOtpVersion())
            "isInitialized" -> result.success(BeamVmNative.nativeIsInitialized())
            else -> result.notImplemented()
        }
    }

    private fun initialize(erlangPath: String, result: Result) {
        scope.launch {
            try {
                val code = BeamVmNative.nativeInit(erlangPath)
                withContext(Dispatchers.Main) {
                    if (code == 0) {
                        result.success(true)
                    } else {
                        result.error("INIT_FAILED", "BEAM VM initialization failed: $code", code)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("INIT_ERROR", e.message, null)
                }
            }
        }
    }

    private fun shutdown(result: Result) {
        scope.launch {
            BeamVmNative.nativeShutdown()
            withContext(Dispatchers.Main) { result.success(null) }
        }
    }

    private fun callFunction(module: String, function: String, args: String, result: Result) {
        scope.launch {
            try {
                val response = BeamVmNative.nativeCall(module, function, args)
                withContext(Dispatchers.Main) { result.success(response) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("CALL_ERROR", e.message, null) }
            }
        }
    }

    private fun sendMessage(processName: String, message: String, result: Result) {
        scope.launch {
            BeamVmNative.nativeSend(processName, message)
            withContext(Dispatchers.Main) { result.success(null) }
        }
    }
}

/** Native JNI bindings for BEAM VM. */
object BeamVmNative {
    external fun nativeInit(erlangPath: String): Int
    external fun nativeIsInitialized(): Boolean
    external fun nativeShutdown()
    external fun nativeGetOtpVersion(): String
    external fun nativeCall(module: String, function: String, argsJson: String): String?
    external fun nativeSend(processName: String, messageJson: String)
}

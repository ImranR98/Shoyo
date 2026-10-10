package dev.imranr.shoyo

import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                "getDownloadNames" -> runAsync(result) {
                    MediaStoreSaver.getDownloadNames(applicationContext)
                }
                "probeNames" -> {
                    val names = call.argument<List<String>>("names")
                    if (names == null) {
                        result.error("BAD_ARGS", "names is required", null)
                    } else {
                        runAsync(result) {
                            names.map { MediaStoreSaver.probeNameTaken(applicationContext, it) }
                        }
                    }
                }
                "saveFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val allowProviderRename =
                        call.argument<Boolean>("allowProviderRename") ?: true
                    if (sourcePath == null || fileName == null) {
                        result.error("BAD_ARGS", "sourcePath and fileName are required", null)
                    } else {
                        runAsync(result) {
                            val saved = MediaStoreSaver.saveFile(
                                applicationContext,
                                sourcePath,
                                fileName,
                                allowProviderRename,
                            )
                            mapOf("displayName" to saved.displayName)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                handler.post { result.success(value) }
            } catch (e: MediaStoreSaver.SaveException) {
                handler.post { result.error(e.code, e.message, null) }
            } catch (e: Exception) {
                handler.post { result.error("IO_ERROR", e.message, null) }
            }
        }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "dev.imranr.shoyo/media_store"
    }
}

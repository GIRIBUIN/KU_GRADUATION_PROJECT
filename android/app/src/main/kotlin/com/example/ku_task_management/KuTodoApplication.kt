package com.example.ku_task_management

import io.flutter.FlutterInjector
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import android.util.Log

/** Keeps the widget quick-create Flutter engine ready before its Activity is opened. */
class KuTodoApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        try {
            warmWidgetQuickCreateEngine()
        } catch (error: Exception) {
            Log.e(TAG, "Could not prewarm widget quick-create engine", error)
        }
    }

    private fun warmWidgetQuickCreateEngine() {
        val cache = FlutterEngineCache.getInstance()
        if (cache.get(WidgetTaskCreateActivity.ENGINE_ID) != null) return

        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)

        val engine = FlutterEngine(applicationContext)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "widgetQuickCreate"),
        )
        cache.put(WidgetTaskCreateActivity.ENGINE_ID, engine)
    }

    private companion object {
        const val TAG = "KuTodoApplication"
    }
}

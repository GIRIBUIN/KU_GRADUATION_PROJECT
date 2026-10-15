package com.example.ku_task_management

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ku.todo/widget-reminders")
            .setMethodCallHandler { call, result ->
                if (call.method == "cancel") {
                    val id = call.argument<String>("taskId")
                    if (id == null) result.error("invalid_task", "taskId is required", null)
                    else { WidgetReminders.cancel(this, id); result.success(null) }
                } else if (call.method == "reconcile") {
                    try {
                        WidgetReminders.restore(applicationContext)
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("widget_reminders", error.message, null)
                    }
                } else result.notImplemented()
            }
    }
}

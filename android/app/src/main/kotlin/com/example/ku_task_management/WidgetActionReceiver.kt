package com.example.ku_task_management

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import java.util.concurrent.Executors

/** Basic widget actions never open a window, Activity or Flutter engine. */
class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        worker.execute {
            try {
                val store = WidgetTaskStore(context)
                val widgetId = intent.getIntExtra("widget_id", 0)
                val kind = intent.getStringExtra("kind") ?: "today"
                when (val action = intent.getStringExtra("action")) {
                    "toggle" -> {
                        val task = store.task(requireNotNull(intent.getStringExtra("task_id")))
                        require(task.status in setOf("active", "completed")) { "먼저 삭제 목록에서 복구해주세요." }
                        store.changeStatus(task.id, if (task.completed) "active" else "completed")
                    }
                    "undo" -> require(store.undo()) { "되돌릴 변경 사항이 없습니다." }
                    "previous", "next" -> {
                        val options = store.options(widgetId, kind)
                        store.saveOptions(widgetId, options.copy(page = (options.page + if (action == "next") 1 else -1).coerceAtLeast(0)))
                    }
                    "refresh" -> store.tasks()
                }
            } catch (error: Exception) {
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(context, error.message ?: "위젯 작업을 처리하지 못했습니다.", Toast.LENGTH_LONG).show()
                }
            } finally {
                try { WidgetWorkspaceRenderer.refreshAll(context) } finally { pending.finish() }
            }
        }
    }

    companion object {
        // Serialize rapid repeated taps so each toggle sees the last committed state.
        private val worker = Executors.newSingleThreadExecutor()
    }
}

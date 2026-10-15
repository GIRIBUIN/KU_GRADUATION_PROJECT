package com.example.ku_task_management

import android.content.Context

/** Compatibility with PendingIntents created by the previous widget version. */
object WidgetTaskCompleter {
    fun completeTask(context: Context, taskId: String, widgetKind: String) {
        val store = WidgetTaskStore(context)
        val task = store.task(taskId)
        require(task.status in setOf("active", "completed"))
        store.changeStatus(taskId, if (widgetKind == "weekly" && task.completed) "active" else "completed")
        WidgetWorkspaceRenderer.refreshAll(context)
    }
}

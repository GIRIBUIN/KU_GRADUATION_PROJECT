package com.example.ku_task_management

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/** 체크 상태를 DB와 두 위젯 전체 캐시에 반영하고 pending 큐로 재시도를 보장한다. */
object WidgetTaskCompleter {
    private const val TODAY_WIDGET_DATA_KEY = "schedule_widget_data"
    private const val WEEKLY_WIDGET_DATA_KEY = "weekly_schedule_widget_data"
    const val WIDGET_REFRESH_REQUIRED = "widget_refresh_required"
    const val WIDGET_PENDING_COMPLETIONS = "widget_pending_completions"
    const val WIDGET_PENDING_UNCOMPLETIONS = "widget_pending_uncompletions"

    fun completeTask(context: Context, taskId: String, widgetKind: String) {
        when (widgetKind) {
            WidgetActions.WIDGET_KIND_WEEKLY -> toggleWeeklyWidgetTask(context, taskId)
            else -> completeTodayWidgetTask(context, taskId)
        }
    }

    private fun completeTodayWidgetTask(context: Context, taskId: String) {
        toggleWidgetTask(context, taskId, TODAY_WIDGET_DATA_KEY)
    }

    private fun toggleWeeklyWidgetTask(context: Context, taskId: String) {
        toggleWidgetTask(context, taskId, WEEKLY_WIDGET_DATA_KEY)
    }

    private fun toggleWidgetTask(context: Context, taskId: String, sourceKey: String) {
        val completed = toggleWidgetTaskInData(context, taskId, sourceKey) ?: return
        val otherKey = if (sourceKey == TODAY_WIDGET_DATA_KEY) WEEKLY_WIDGET_DATA_KEY else TODAY_WIDGET_DATA_KEY
        setTaskStateInData(context, taskId, otherKey, completed)
        if (completed) {
            markTaskCompleted(context, taskId)
            addPendingWidgetCompletion(context, taskId)
            removePendingWidgetUncompletion(context, taskId)
        } else {
            markTaskUncompleted(context, taskId)
            addPendingWidgetUncompletion(context, taskId)
            removePendingWidgetCompletion(context, taskId)
        }
        HomeWidgetPlugin.getData(context).edit().putBoolean(WIDGET_REFRESH_REQUIRED, true).apply()
        ScheduleWidgetProvider.requestUpdate(context)
        WeeklyScheduleWidgetProvider.requestUpdate(context)
    }

    private fun markTaskUncompleted(context: Context, taskId: String) {
        val file = resolveDatabaseFile(context) ?: return
        try {
            SQLiteDatabase.openDatabase(file.absolutePath, null, SQLiteDatabase.OPEN_READWRITE).use { db ->
                db.execSQL("UPDATE tasks SET status = 'active', completed_at = NULL, updated_at = ? WHERE id = ? AND status = 'completed'",
                    arrayOf<Any>(System.currentTimeMillis() / 1000L, taskId))
            }
        } catch (_: Exception) {
            // Pending queue retries through the existing repository on next refresh.
        }
    }

    private fun markTaskCompleted(context: Context, taskId: String): Boolean {
        val dbFile = resolveDatabaseFile(context) ?: return false
        val nowSeconds = System.currentTimeMillis() / 1000L

        return try {
            SQLiteDatabase.openDatabase(
                dbFile.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE,
            ).use { db ->
                val updated = db.compileStatement(
                    """
                    UPDATE tasks
                    SET status = 'completed',
                        updated_at = ?,
                        completed_at = ?
                    WHERE id = ?
                      AND status = 'active'
                    """.trimIndent(),
                ).apply {
                    bindLong(1, nowSeconds)
                    bindLong(2, nowSeconds)
                    bindString(3, taskId)
                }.executeUpdateDelete()

                updated > 0
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun resolveDatabaseFile(context: Context): File? {
        HomeWidgetPlugin.getData(context)
            .getString("widget_db_path", null)
            ?.let { configuredPath ->
                val configuredFile = File(configuredPath)
                if (configuredFile.exists()) {
                    return configuredFile
                }
            }

        val candidates = listOf(
            File(context.getDir("app_flutter", Context.MODE_PRIVATE), "ku_task_management.sqlite"),
            File(context.filesDir, "ku_task_management.sqlite"),
            File(context.applicationInfo.dataDir, "app_flutter/ku_task_management.sqlite"),
        )

        candidates.firstOrNull { it.exists() }?.let { return it }

        val appFlutterDir = context.getDir("app_flutter", Context.MODE_PRIVATE)
        return appFlutterDir.listFiles()
            ?.firstOrNull { file ->
                file.isFile &&
                    file.name.startsWith("ku_task_management") &&
                    file.extension == "sqlite"
            }
    }

    private fun setTaskStateInData(context: Context, taskId: String, key: String, completed: Boolean) {
        val prefs = HomeWidgetPlugin.getData(context)
        try {
            val root = JSONObject(prefs.getString(key, null) ?: return)
            val tasks = root.optJSONArray("tasks") ?: return
            for (i in 0 until tasks.length()) {
                val task = tasks.getJSONObject(i)
                if (task.optString("id") == taskId && task.optBoolean("isCompleted") != completed) {
                    toggleWidgetTaskInData(context, taskId, key)
                    return
                }
            }
        } catch (_: Exception) { }
    }

    private fun toggleWidgetTaskInData(context: Context, taskId: String, key: String): Boolean? {
        val prefs = HomeWidgetPlugin.getData(context)
        val rawJson = prefs.getString(key, null) ?: return null

        return try {
            val root = JSONObject(rawJson)
            val tasksArray = root.optJSONArray("tasks") ?: JSONArray()
            var completedCount = root.optInt("completedCount", 0)
            var toggledToCompleted: Boolean? = null

            for (index in 0 until tasksArray.length()) {
                val taskJson = tasksArray.optJSONObject(index) ?: continue
                if (taskJson.optString("id") != taskId) {
                    continue
                }

                val isCompleted = taskJson.optBoolean("isCompleted", false)
                if (isCompleted) {
                    taskJson.put("isCompleted", false)
                    completedCount = (completedCount - 1).coerceAtLeast(0)
                    toggledToCompleted = false
                } else {
                    taskJson.put("isCompleted", true)
                    completedCount += 1
                    toggledToCompleted = true
                }
                break
            }

            if (toggledToCompleted == null) {
                return null
            }

            root.put("completedCount", completedCount)
            val sorted = (0 until tasksArray.length()).map { tasksArray.getJSONObject(it) }
                .sortedWith(compareBy<JSONObject> { it.optBoolean("isCompleted", false) }
                    .thenBy { it.optLong("sortTimestamp", 0L) })
            root.put("tasks", JSONArray(sorted))
            prefs.edit().putString(key, root.toString()).commit()
            toggledToCompleted
        } catch (_: Exception) {
            null
        }
    }

    private fun addPendingWidgetCompletion(context: Context, taskId: String) {
        addPendingWidgetTaskId(context, WIDGET_PENDING_COMPLETIONS, taskId)
    }

    private fun removePendingWidgetCompletion(context: Context, taskId: String) {
        removePendingWidgetTaskId(context, WIDGET_PENDING_COMPLETIONS, taskId)
    }

    private fun addPendingWidgetUncompletion(context: Context, taskId: String) {
        addPendingWidgetTaskId(context, WIDGET_PENDING_UNCOMPLETIONS, taskId)
    }

    private fun removePendingWidgetUncompletion(context: Context, taskId: String) {
        removePendingWidgetTaskId(context, WIDGET_PENDING_UNCOMPLETIONS, taskId)
    }

    private fun addPendingWidgetTaskId(context: Context, key: String, taskId: String) {
        val prefs = HomeWidgetPlugin.getData(context)
        val pendingArray = readPendingTaskIds(prefs.getString(key, "[]"))
        if (pendingArray.contains(taskId)) {
            return
        }
        pendingArray.put(taskId)
        prefs.edit().putString(key, pendingArray.toString()).apply()
    }

    private fun removePendingWidgetTaskId(context: Context, key: String, taskId: String) {
        val prefs = HomeWidgetPlugin.getData(context)
        val pendingArray = readPendingTaskIds(prefs.getString(key, "[]"))
        val filtered = JSONArray()
        for (index in 0 until pendingArray.length()) {
            val currentId = pendingArray.optString(index)
            if (currentId != taskId) {
                filtered.put(currentId)
            }
        }
        prefs.edit().putString(key, filtered.toString()).apply()
    }

    private fun readPendingTaskIds(raw: String?): JSONArray {
        return try {
            JSONArray(raw ?: "[]")
        } catch (_: Exception) {
            JSONArray()
        }
    }

    private fun JSONArray.contains(taskId: String): Boolean {
        for (index in 0 until length()) {
            if (optString(index) == taskId) {
                return true
            }
        }
        return false
    }
}

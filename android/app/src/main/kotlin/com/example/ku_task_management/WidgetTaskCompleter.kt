package com.example.ku_task_management

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object WidgetTaskCompleter {
    private const val TODAY_WIDGET_DATA_KEY = "schedule_widget_data"
    private const val WEEKLY_WIDGET_DATA_KEY = "weekly_schedule_widget_data"
    const val WIDGET_REFRESH_REQUIRED = "widget_refresh_required"

    fun completeTask(context: Context, taskId: String) {
        removeTaskFromTodayWidgetData(context, taskId)
        markCompletedInWeeklyWidgetData(context, taskId)
        ScheduleWidgetProvider.requestUpdate(context)
        WeeklyScheduleWidgetProvider.requestUpdate(context)

        val dbUpdated = markTaskCompleted(context, taskId)
        if (dbUpdated) {
            HomeWidgetPlugin.getData(context)
                .edit()
                .putBoolean(WIDGET_REFRESH_REQUIRED, true)
                .apply()
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

    private fun removeTaskFromTodayWidgetData(context: Context, taskId: String) {
        val prefs = HomeWidgetPlugin.getData(context)
        val rawJson = prefs.getString(TODAY_WIDGET_DATA_KEY, null) ?: return

        try {
            val root = JSONObject(rawJson)
            val tasksArray = root.optJSONArray("tasks") ?: JSONArray()
            val filteredTasks = JSONArray()

            for (index in 0 until tasksArray.length()) {
                val taskJson = tasksArray.optJSONObject(index) ?: continue
                if (taskJson.optString("id") != taskId) {
                    filteredTasks.put(taskJson)
                }
            }

            root.put("tasks", filteredTasks)
            root.put("todayCount", filteredTasks.length())
            prefs.edit().putString(TODAY_WIDGET_DATA_KEY, root.toString()).commit()
        } catch (_: Exception) {
            // Ignore malformed widget cache. App will rebuild it on next launch.
        }
    }

    private fun markCompletedInWeeklyWidgetData(context: Context, taskId: String) {
        val prefs = HomeWidgetPlugin.getData(context)
        val rawJson = prefs.getString(WEEKLY_WIDGET_DATA_KEY, null) ?: return

        try {
            val root = JSONObject(rawJson)
            val tasksArray = root.optJSONArray("tasks") ?: JSONArray()
            var completedCount = root.optInt("completedCount", 0)
            var taskUpdated = false

            for (index in 0 until tasksArray.length()) {
                val taskJson = tasksArray.optJSONObject(index) ?: continue
                if (taskJson.optString("id") != taskId) {
                    continue
                }
                if (!taskJson.optBoolean("isCompleted", false)) {
                    taskJson.put("isCompleted", true)
                    completedCount += 1
                    taskUpdated = true
                }
                break
            }

            if (!taskUpdated) {
                return
            }

            root.put("completedCount", completedCount)
            prefs.edit().putString(WEEKLY_WIDGET_DATA_KEY, root.toString()).commit()
        } catch (_: Exception) {
            // Ignore malformed widget cache. App will rebuild it on next launch.
        }
    }
}

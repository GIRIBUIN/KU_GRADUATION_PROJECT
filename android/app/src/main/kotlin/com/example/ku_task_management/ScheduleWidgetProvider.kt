package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class ScheduleWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val tasks = parseTasks(widgetData.getString(WIDGET_DATA_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.schedule_widget).apply {
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                val rowIds = intArrayOf(R.id.task_row_0, R.id.task_row_1, R.id.task_row_2)
                val titleIds = intArrayOf(R.id.task_title_0, R.id.task_title_1, R.id.task_title_2)
                val dueIds = intArrayOf(R.id.task_due_0, R.id.task_due_1, R.id.task_due_2)

                for (index in rowIds.indices) {
                    val task = tasks.getOrNull(index)
                    if (task == null) {
                        setViewVisibility(rowIds[index], View.GONE)
                        continue
                    }

                    setViewVisibility(rowIds[index], View.VISIBLE)
                    setTextViewText(titleIds[index], task.title)
                    setTextViewText(dueIds[index], task.dueLabel)
                    setTextColor(dueIds[index], parseColor(task.dueColorHex))
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private data class WidgetTask(
        val title: String,
        val dueLabel: String,
        val dueColorHex: String,
    )

    private fun parseTasks(rawJson: String?): List<WidgetTask> {
        if (rawJson.isNullOrBlank()) {
            return emptyList()
        }

        return try {
            val tasksArray =
                JSONObject(rawJson).optJSONArray("tasks") ?: JSONArray()
            buildList {
                for (index in 0 until tasksArray.length()) {
                    val taskJson = tasksArray.optJSONObject(index) ?: continue
                    val title = taskJson.optString("title").trim()
                    if (title.isEmpty()) {
                        continue
                    }
                    add(
                        WidgetTask(
                            title = title,
                            dueLabel = taskJson.optString("dueLabel", "마감 없음"),
                            dueColorHex = taskJson.optString("dueColorHex", DEFAULT_DUE_COLOR),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun parseColor(hex: String): Int {
        return try {
            Color.parseColor(hex)
        } catch (_: IllegalArgumentException) {
            Color.parseColor(DEFAULT_DUE_COLOR)
        }
    }

    companion object {
        private const val WIDGET_DATA_KEY = "schedule_widget_data"
        private const val DEFAULT_DUE_COLOR = "#6B7280"
    }
}

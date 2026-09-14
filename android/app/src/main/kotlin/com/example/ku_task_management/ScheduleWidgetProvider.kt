package com.example.ku_task_management

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
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
        val payload = parseWidgetData(widgetData.getString(WIDGET_DATA_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.schedule_widget).apply {
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                setTextViewText(R.id.widget_date, payload.headerDateLabel)

                val rowIds = intArrayOf(R.id.task_row_0, R.id.task_row_1, R.id.task_row_2)
                val dividerIds = intArrayOf(R.id.task_divider_0, R.id.task_divider_1)
                val checkboxIds = intArrayOf(
                    R.id.task_checkbox_0,
                    R.id.task_checkbox_1,
                    R.id.task_checkbox_2,
                )
                val accentIds = intArrayOf(R.id.task_accent_0, R.id.task_accent_1, R.id.task_accent_2)
                val timeIds = intArrayOf(R.id.task_time_0, R.id.task_time_1, R.id.task_time_2)
                val titleIds = intArrayOf(R.id.task_title_0, R.id.task_title_1, R.id.task_title_2)
                val dueIds = intArrayOf(R.id.task_due_0, R.id.task_due_1, R.id.task_due_2)

                for (index in rowIds.indices) {
                    val task = payload.tasks.getOrNull(index)
                    if (task == null) {
                        setViewVisibility(rowIds[index], View.GONE)
                        if (index < dividerIds.size) {
                            setViewVisibility(dividerIds[index], View.GONE)
                        }
                        continue
                    }

                    setViewVisibility(rowIds[index], View.VISIBLE)
                    if (index < dividerIds.size) {
                        setViewVisibility(
                            dividerIds[index],
                            if (payload.tasks.size > index + 1) View.VISIBLE else View.GONE,
                        )
                    }

                    setTextViewText(timeIds[index], task.timeLabel)
                    setTextViewText(titleIds[index], task.title)
                    setTextViewText(dueIds[index], task.dueLabel)
                    setTextColor(dueIds[index], parseColor(task.dueColorHex))
                    setInt(accentIds[index], "setBackgroundColor", parseColor(task.accentColorHex))

                    val completeIntent = completeTaskPendingIntent(
                        context = context,
                        taskId = task.id,
                        requestCode = CHECKBOX_REQUEST_CODE_BASE + index,
                    )
                    setOnClickPendingIntent(checkboxIds[index], completeIntent)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private data class WidgetTask(
        val id: String,
        val title: String,
        val timeLabel: String,
        val dueLabel: String,
        val accentColorHex: String,
        val dueColorHex: String,
    )

    private data class WidgetPayload(
        val headerDateLabel: String,
        val tasks: List<WidgetTask>,
    ) {
        companion object {
            fun empty() = WidgetPayload(headerDateLabel = "", tasks = emptyList())
        }
    }

    private fun parseWidgetData(rawJson: String?): WidgetPayload {
        if (rawJson.isNullOrBlank()) {
            return WidgetPayload.empty()
        }

        return try {
            val root = JSONObject(rawJson)
            val tasksArray = root.optJSONArray("tasks") ?: JSONArray()
            val tasks = buildList {
                for (index in 0 until tasksArray.length()) {
                    val taskJson = tasksArray.optJSONObject(index) ?: continue
                    val id = taskJson.optString("id").trim()
                    val title = taskJson.optString("title").trim()
                    if (id.isEmpty() || title.isEmpty()) {
                        continue
                    }
                    add(
                        WidgetTask(
                            id = id,
                            title = title,
                            timeLabel = taskJson.optString("timeLabel", "--:--"),
                            dueLabel = taskJson.optString("dueLabel", "마감 없음"),
                            accentColorHex = taskJson.optString("accentColorHex", DEFAULT_ACCENT_COLOR),
                            dueColorHex = taskJson.optString("dueColorHex", DEFAULT_DUE_COLOR),
                        ),
                    )
                }
            }

            WidgetPayload(
                headerDateLabel = root.optString("headerDateLabel", ""),
                tasks = tasks,
            )
        } catch (_: Exception) {
            WidgetPayload.empty()
        }
    }

    private fun completeTaskPendingIntent(
        context: Context,
        taskId: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = HOME_WIDGET_BACKGROUND_ACTION
            data = Uri.parse("kutodo://completeTask?taskId=${Uri.encode(taskId)}")
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }

        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
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
        private const val HOME_WIDGET_BACKGROUND_ACTION =
            "es.antonborri.home_widget.action.BACKGROUND"
        private const val DEFAULT_ACCENT_COLOR = "#1262D6"
        private const val DEFAULT_DUE_COLOR = "#6B7280"
        private const val CHECKBOX_REQUEST_CODE_BASE = 10_000
    }
}

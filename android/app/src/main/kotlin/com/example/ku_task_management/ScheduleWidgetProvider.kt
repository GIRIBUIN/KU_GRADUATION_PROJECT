package com.example.ku_task_management

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
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
                val openAppIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_header, openAppIntent)

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
                    setInt(accentIds[index], "setBackgroundColor", parseColor(task.accentColorHex))

                    val completeIntent = completeTaskPendingIntent(
                        context = context,
                        taskId = task.id,
                        requestCode = CHECKBOX_REQUEST_CODE_BASE + task.id.hashCode(),
                    )
                    setOnClickPendingIntent(rowIds[index], completeIntent)
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
        val accentColorHex: String,
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
                            accentColorHex = taskJson.optString("accentColorHex", DEFAULT_ACCENT_COLOR),
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
        val intent = Intent(context, WidgetTaskCompleteActivity::class.java).apply {
            putExtra(WidgetActions.EXTRA_TASK_ID, taskId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val options = ActivityOptions.makeBasic()
            if (Build.VERSION.SDK_INT >= 35) {
                options.setPendingIntentCreatorBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                )
            } else {
                options.pendingIntentBackgroundActivityStartMode =
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
            }
            return PendingIntent.getActivity(context, requestCode, intent, flags, options.toBundle())
        }

        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    private fun parseColor(hex: String): Int {
        return try {
            Color.parseColor(hex)
        } catch (_: IllegalArgumentException) {
            Color.parseColor(DEFAULT_ACCENT_COLOR)
        }
    }

    companion object {
        private const val WIDGET_DATA_KEY = "schedule_widget_data"
        private const val DEFAULT_ACCENT_COLOR = "#1262D6"
        private const val CHECKBOX_REQUEST_CODE_BASE = 10_000

        fun requestUpdate(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, ScheduleWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (widgetIds.isEmpty()) {
                return
            }

            ScheduleWidgetProvider().onUpdate(
                context,
                appWidgetManager,
                widgetIds,
                HomeWidgetPlugin.getData(context),
            )
        }
    }
}

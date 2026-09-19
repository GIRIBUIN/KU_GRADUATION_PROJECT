package com.example.ku_task_management

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.Paint
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class WeeklyScheduleWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = parseWidgetData(widgetData.getString(WIDGET_DATA_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.weekly_schedule_widget).apply {
                val openAppIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_header, openAppIntent)

                setTextViewText(R.id.widget_week_range, payload.weekRangeLabel)
                setTextViewText(
                    R.id.widget_progress_label,
                    formatProgressLabel(payload.completedCount, payload.totalCount),
                )
                setProgressBar(
                    R.id.widget_progress,
                    100,
                    payload.progressPercent,
                    false,
                )

                bindTaskRows(context, payload)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun RemoteViews.bindTaskRows(context: Context, payload: WidgetPayload) {
        val rowIds = intArrayOf(
            R.id.task_row_0,
            R.id.task_row_1,
            R.id.task_row_2,
            R.id.task_row_3,
            R.id.task_row_4,
        )
        val dividerIds = intArrayOf(
            R.id.task_divider_0,
            R.id.task_divider_1,
            R.id.task_divider_2,
            R.id.task_divider_3,
        )
        val checkboxIds = intArrayOf(
            R.id.task_checkbox_0,
            R.id.task_checkbox_1,
            R.id.task_checkbox_2,
            R.id.task_checkbox_3,
            R.id.task_checkbox_4,
        )
        val titleIds = intArrayOf(
            R.id.task_title_0,
            R.id.task_title_1,
            R.id.task_title_2,
            R.id.task_title_3,
            R.id.task_title_4,
        )
        val categoryIds = intArrayOf(
            R.id.task_category_0,
            R.id.task_category_1,
            R.id.task_category_2,
            R.id.task_category_3,
            R.id.task_category_4,
        )
        val dueIds = intArrayOf(
            R.id.task_due_0,
            R.id.task_due_1,
            R.id.task_due_2,
            R.id.task_due_3,
            R.id.task_due_4,
        )

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

            setTextViewText(titleIds[index], task.title)
            setTextViewText(categoryIds[index], task.categoryLabel)
            setInt(categoryIds[index], "setBackgroundColor", parseColor(task.categoryBackgroundHex))
            setTextColor(categoryIds[index], parseColor(task.categoryTextHex))
            setTextViewText(dueIds[index], task.dueLabel)
            setTextColor(dueIds[index], parseColor(task.dueColorHex))

            if (task.isCompleted) {
                setImageViewResource(checkboxIds[index], R.drawable.widget_checkbox_checked)
                setTextColor(titleIds[index], parseColor(COMPLETED_TITLE_COLOR))
                setInt(
                    titleIds[index],
                    "setPaintFlags",
                    Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG,
                )
                setOnClickPendingIntent(rowIds[index], null)
                setOnClickPendingIntent(checkboxIds[index], null)
            } else {
                setImageViewResource(checkboxIds[index], R.drawable.widget_checkbox_unchecked)
                setTextColor(titleIds[index], parseColor(DEFAULT_TITLE_COLOR))
                setInt(titleIds[index], "setPaintFlags", Paint.ANTI_ALIAS_FLAG)

                val completeIntent = completeTaskPendingIntent(
                    context = context,
                    taskId = task.id,
                    requestCode = CHECKBOX_REQUEST_CODE_BASE + task.id.hashCode(),
                )
                setOnClickPendingIntent(rowIds[index], completeIntent)
                setOnClickPendingIntent(checkboxIds[index], completeIntent)
            }
        }
    }

    private data class WidgetTask(
        val id: String,
        val title: String,
        val categoryLabel: String,
        val categoryBackgroundHex: String,
        val categoryTextHex: String,
        val dueLabel: String,
        val dueColorHex: String,
        val isCompleted: Boolean,
    )

    private data class WidgetPayload(
        val weekRangeLabel: String,
        val completedCount: Int,
        val totalCount: Int,
        val tasks: List<WidgetTask>,
    ) {
        val progressPercent: Int
            get() {
                if (totalCount <= 0) {
                    return 0
                }
                return ((completedCount.toFloat() / totalCount.toFloat()) * 100f)
                    .toInt()
                    .coerceIn(0, 100)
            }

        companion object {
            fun empty() = WidgetPayload(
                weekRangeLabel = "",
                completedCount = 0,
                totalCount = 0,
                tasks = emptyList(),
            )
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
                            categoryLabel = taskJson.optString("categoryLabel", "개인"),
                            categoryBackgroundHex = taskJson.optString(
                                "categoryBackgroundHex",
                                DEFAULT_CATEGORY_BACKGROUND,
                            ),
                            categoryTextHex = taskJson.optString(
                                "categoryTextHex",
                                DEFAULT_CATEGORY_TEXT,
                            ),
                            dueLabel = taskJson.optString("dueLabel", "D-day"),
                            dueColorHex = taskJson.optString("dueColorHex", DEFAULT_DUE_COLOR),
                            isCompleted = taskJson.optBoolean("isCompleted", false),
                        ),
                    )
                }
            }

            WidgetPayload(
                weekRangeLabel = root.optString("weekRangeLabel", ""),
                completedCount = root.optInt("completedCount", 0),
                totalCount = root.optInt("totalCount", 0),
                tasks = tasks,
            )
        } catch (_: Exception) {
            WidgetPayload.empty()
        }
    }

    private fun formatProgressLabel(completedCount: Int, totalCount: Int): String {
        return "$completedCount / $totalCount 완료"
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

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

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
            Color.parseColor(DEFAULT_DUE_COLOR)
        }
    }

    companion object {
        private const val WIDGET_DATA_KEY = "weekly_schedule_widget_data"
        private const val DEFAULT_DUE_COLOR = "#1262D6"
        private const val DEFAULT_TITLE_COLOR = "#111827"
        private const val COMPLETED_TITLE_COLOR = "#9CA3AF"
        private const val DEFAULT_CATEGORY_BACKGROUND = "#FCE7F3"
        private const val DEFAULT_CATEGORY_TEXT = "#DB2777"
        private const val CHECKBOX_REQUEST_CODE_BASE = 20_000

        fun requestUpdate(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, WeeklyScheduleWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (widgetIds.isEmpty()) {
                return
            }

            WeeklyScheduleWidgetProvider().onUpdate(
                context,
                appWidgetManager,
                widgetIds,
                HomeWidgetPlugin.getData(context),
            )
        }
    }
}

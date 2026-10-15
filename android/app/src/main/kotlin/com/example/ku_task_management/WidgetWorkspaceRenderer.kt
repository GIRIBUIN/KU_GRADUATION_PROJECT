package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.graphics.Color
import android.graphics.Paint
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

object WidgetWorkspaceRenderer {
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for ((provider, kind) in listOf(ScheduleWidgetProvider::class.java to "today",
                WeeklyScheduleWidgetProvider::class.java to "weekly",
                CalendarWidgetProvider::class.java to "calendar")) {
            manager.getAppWidgetIds(ComponentName(context, provider)).forEach { render(context, manager, it, kind) }
        }
    }

    fun render(context: Context, manager: AppWidgetManager, widgetId: Int, kind: String) {
        if (kind == "calendar") {
            WidgetCalendarRenderer.render(context, manager, widgetId)
            return
        }
        val dimensions = manager.getAppWidgetOptions(widgetId)
        val height = dimensions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, if (kind == "weekly") 203 else 180)
        val width = dimensions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, if (kind == "weekly") 276 else 180)
        val compact = height < 210 || width < 220
        val singleLine = height < 140
        val views = RemoteViews(context.packageName, if (compact) R.layout.widget_workspace_compact else R.layout.widget_workspace)
        val store = WidgetTaskStore(context)
        val options = store.options(widgetId, kind)
        val palette = WidgetPalette.from(options)
        val foreground = palette.text
        val muted = palette.muted
        views.setInt(R.id.widget_card_background, "setColorFilter", palette.surface)
        views.setInt(R.id.widget_card_background, "setImageAlpha", Color.alpha(palette.surfaceWithOpacity(options.opacity)))
        views.setTextColor(R.id.workspace_date, palette.accent)
        views.setTextColor(R.id.workspace_title, foreground)
        views.setTextColor(R.id.workspace_summary, muted)
        views.setTextColor(R.id.workspace_more, muted)
        views.setTextColor(R.id.workspace_empty, muted)
        views.setTextViewText(R.id.workspace_title, periodLabel(options.period))
        val now = System.currentTimeMillis() / 1000
        val date = Instant.ofEpochSecond(now).atZone(ZoneId.systemDefault())
        val dateLabel = if (options.period == "week") {
            val monday = date.toLocalDate().minusDays((date.dayOfWeek.value - 1).toLong())
            val sunday = monday.plusDays(6)
            "${monday.monthValue}/${monday.dayOfMonth} ~ ${sunday.monthValue}/${sunday.dayOfMonth}"
        } else date.format(DateTimeFormatter.ofPattern("M월 d일 (E)", Locale.KOREAN))
        views.setTextViewText(R.id.workspace_date, dateLabel)
        // Every entry point expands the same list. Compact checkmarks only show status.
        val expand = WidgetWorkspaceActivity.pending(context, "list", widgetId = widgetId, kind = kind)
        for (viewId in listOf(R.id.workspace_surface, R.id.workspace_header, R.id.workspace_empty, R.id.workspace_more))
            views.setOnClickPendingIntent(viewId, expand)
        views.removeAllViews(R.id.workspace_rows)
        try {
            val pins = store.pins()
            val allTasks = store.tasks()
            val urgentDays = store.appSetting("urgentDueDays", "3").toIntOrNull() ?: 3
            val tasks = WidgetTaskPolicy.select(allTasks, options, now, pins, urgentDays)
            val largeRows = options.largeText || context.resources.configuration.fontScale > 1.3f
            val rowLayout = when {
                singleLine -> R.layout.widget_workspace_row_single
                largeRows -> R.layout.widget_workspace_row_large
                compact -> R.layout.widget_workspace_row_compact
                else -> R.layout.widget_workspace_row
            }
            val rowHeight = when { singleLine -> 26; largeRows -> 72; compact -> 40; else -> 52 }
            val count = ((height - if (compact) 46 else 110) / rowHeight).coerceIn(1, 12)
            for (task in tasks.take(count)) {
                val row = RemoteViews(context.packageName, rowLayout)
                row.setTextViewText(R.id.workspace_row_title,
                    (if (task.id in pins) "★ " else "") + task.title)
                row.setTextColor(R.id.workspace_row_title, if (task.completed) muted else foreground)
                row.setTextViewTextSize(R.id.workspace_row_title, TypedValue.COMPLEX_UNIT_SP,
                    if (singleLine) 12f else if (options.largeText) 16f else if (compact) 13f else 14f)
                row.setInt(R.id.workspace_row_title, "setPaintFlags", Paint.ANTI_ALIAS_FLAG or
                    if (task.completed) Paint.STRIKE_THRU_TEXT_FLAG else 0)
                row.setImageViewResource(R.id.workspace_row_check,
                    if (task.completed) R.drawable.widget_checkbox_checked else R.drawable.widget_checkbox_unchecked)
                row.setTextViewText(R.id.workspace_row_detail,
                    (if (task.academic && task.course.isNotEmpty()) "${task.course} · " else "") + dueLabel(task.due, now))
                row.setTextColor(R.id.workspace_row_detail,
                    if (task.due != null && task.due < now && !task.completed) palette.red else muted)
                row.setOnClickPendingIntent(R.id.workspace_row_body, expand)
                views.addView(R.id.workspace_rows, row)
            }
            views.setTextViewText(R.id.workspace_summary, "${tasks.size}개")
            val remaining = (tasks.size - count).coerceAtLeast(0)
            views.setViewVisibility(R.id.workspace_more, if (remaining > 0) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.workspace_more, "+${remaining}개 일정")
            views.setViewVisibility(R.id.workspace_empty, if (tasks.isEmpty()) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.workspace_empty, "등록된 일정이 없습니다.")
        } catch (error: Exception) {
            views.setViewVisibility(R.id.workspace_empty, View.VISIBLE)
            views.setTextViewText(R.id.workspace_empty, error.message ?: "일정을 불러오지 못했습니다. 새로고침해주세요.")
            views.setTextViewText(R.id.workspace_summary, "일정을 불러오지 못했습니다")
        }
        manager.updateAppWidget(widgetId, views)
    }

    fun periodLabel(value: String) = when (value) {
        "week" -> "이번 주 일정"; "urgent" -> "마감 임박"; "overdue" -> "기한 초과"
        "all" -> "전체 일정"; "pinned" -> "중요 일정"; "trash" -> "삭제·제외된 일정"; else -> "오늘 할 일정"
    }
    fun originLabel(value: String) = when (value) { "personal" -> "개인"; "ecampus" -> "학업"; else -> "전체" }
    fun dueLabel(due: Long?, now: Long = System.currentTimeMillis() / 1000): String {
        if (due == null) return "마감 없음"
        val zone = ZoneId.systemDefault()
        val date = Instant.ofEpochSecond(due).atZone(zone)
        val today = Instant.ofEpochSecond(now).atZone(zone).toLocalDate()
        val days = java.time.temporal.ChronoUnit.DAYS.between(today, date.toLocalDate())
        val time = date.format(DateTimeFormatter.ofPattern("HH:mm"))
        return if (due < now) "기한 초과 · ${date.format(DateTimeFormatter.ofPattern("M/d HH:mm"))}"
        else when (days) {
            0L -> "오늘 $time"; 1L -> "내일 $time"; else -> "D-$days · ${date.format(DateTimeFormatter.ofPattern("M/d HH:mm"))}"
        }
    }
}

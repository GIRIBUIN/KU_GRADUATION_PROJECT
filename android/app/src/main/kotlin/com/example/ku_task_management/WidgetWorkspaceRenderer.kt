package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.graphics.Color
import android.graphics.Paint
import android.os.Bundle
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
                WeeklyScheduleWidgetProvider::class.java to "weekly")) {
            manager.getAppWidgetIds(ComponentName(context, provider)).forEach { render(context, manager, it, kind) }
        }
    }

    fun render(context: Context, manager: AppWidgetManager, widgetId: Int, kind: String) {
        val views = RemoteViews(context.packageName, R.layout.widget_workspace)
        val store = WidgetTaskStore(context)
        val options = store.options(widgetId, kind)
        val foreground = Color.parseColor(if (options.dark) "#F3F4F6" else "#111827")
        val muted = Color.parseColor(if (options.dark) "#CBD5E1" else "#6B7280")
        val surface = Color.parseColor(if (options.dark) "#182337" else "#FFFFFF")
        views.setInt(R.id.workspace_surface, "setBackgroundColor", surface)
        views.setInt(R.id.workspace_surface, "setBackgroundColor",
            (surface and 0x00ffffff) or ((options.opacity.coerceIn(20, 100) * 255 / 100) shl 24))
        views.setTextColor(R.id.workspace_title, foreground)
        views.setTextColor(R.id.workspace_summary, muted)
        views.setTextColor(R.id.workspace_page, muted)
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
        fun bind(viewId: Int, action: String, taskId: String? = null) {
            views.setOnClickPendingIntent(viewId, WidgetWorkspaceActivity.pending(context, action, taskId, widgetId, kind))
        }
        bind(R.id.workspace_header, "list"); bind(R.id.workspace_add, "add")
        bind(R.id.workspace_expand, "list"); bind(R.id.workspace_settings, "settings")
        bind(R.id.workspace_previous, "previous"); bind(R.id.workspace_next, "next")
        bind(R.id.workspace_undo, "undo"); bind(R.id.workspace_refresh, "refresh")
        views.removeAllViews(R.id.workspace_rows)
        try {
            val pins = store.pins()
            val allTasks = store.tasks()
            val urgentDays = store.appSetting("urgentDueDays", "3").toIntOrNull() ?: 3
            val tasks = WidgetTaskPolicy.select(allTasks, options, now, pins, urgentDays)
            val progressTasks = WidgetTaskPolicy.select(allTasks, options.copy(showCompleted = true), now, pins, urgentDays)
            val height = manager.getAppWidgetOptions(widgetId).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
                if (kind == "weekly") 340 else 280)
            val largeRows = options.largeText || context.resources.configuration.fontScale > 1.3f
            val count = ((height - 142) / if (largeRows) 72 else 52).coerceIn(1, 8)
            val pages = ((tasks.size + count - 1) / count).coerceAtLeast(1)
            val page = options.page.coerceIn(0, pages - 1)
            if (page != options.page) store.saveOptions(widgetId, options.copy(page = page))
            for (task in tasks.drop(page * count).take(count)) {
                val row = RemoteViews(context.packageName, if (largeRows) R.layout.widget_workspace_row_large else R.layout.widget_workspace_row)
                row.setTextViewText(R.id.workspace_row_title,
                    (if (task.id in pins) "★ " else "") + task.title)
                row.setTextColor(R.id.workspace_row_title, if (task.completed) muted else foreground)
                row.setTextViewTextSize(R.id.workspace_row_title, TypedValue.COMPLEX_UNIT_SP,
                    if (options.largeText) 16f else 14f)
                row.setInt(R.id.workspace_row_title, "setPaintFlags", Paint.ANTI_ALIAS_FLAG or
                    if (task.completed) Paint.STRIKE_THRU_TEXT_FLAG else 0)
                row.setImageViewResource(R.id.workspace_row_check,
                    if (task.completed) R.drawable.widget_checkbox_checked else R.drawable.widget_checkbox_unchecked)
                val priority = when (task.priority) { "high" -> " · 높음"; "medium" -> " · 보통"; "low" -> " · 낮음"; else -> "" }
                val progress = if (task.subTotal > 0) " · ${task.subDone}/${task.subTotal}" else ""
                row.setTextViewText(R.id.workspace_row_detail,
                    "${if (task.academic) task.course.ifEmpty { "학업" } else "개인"} · ${dueLabel(task.due, now)}$priority$progress")
                row.setTextColor(R.id.workspace_row_detail,
                    if (task.due != null && task.due < now && !task.completed) Color.parseColor("#E72E2E") else muted)
                row.setOnClickPendingIntent(R.id.workspace_row_check,
                    WidgetWorkspaceActivity.pending(context, "toggle", task.id, widgetId, kind))
                row.setOnClickPendingIntent(R.id.workspace_row_body,
                    WidgetWorkspaceActivity.pending(context, "edit", task.id, widgetId, kind))
                views.addView(R.id.workspace_rows, row)
            }
            val completed = progressTasks.count { it.completed }
            views.setTextViewText(R.id.workspace_summary, if (options.period == "trash")
                "${tasks.size}개 · ${originLabel(options.origin)} · 선택해서 복구"
                else "${tasks.size}개 표시 · $completed/${progressTasks.size} 완료 · ${originLabel(options.origin)}")
            views.setViewVisibility(R.id.workspace_progress, if (options.period == "trash") View.GONE else View.VISIBLE)
            views.setProgressBar(R.id.workspace_progress, progressTasks.size.coerceAtLeast(1), completed, false)
            views.setTextViewText(R.id.workspace_page, "${page + 1} / $pages")
            views.setViewVisibility(R.id.workspace_empty, if (tasks.isEmpty()) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.workspace_empty, "표시할 일정이 없습니다.\n+ 추가 또는 설정에서 표시 범위를 바꿔보세요.")
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

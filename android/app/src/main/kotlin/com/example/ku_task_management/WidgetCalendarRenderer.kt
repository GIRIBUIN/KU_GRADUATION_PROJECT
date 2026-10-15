package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/** A quiet month grid; management lives in the floating calendar workspace. */
object WidgetCalendarRenderer {
    fun render(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_calendar)
        val store = WidgetTaskStore(context)
        val options = store.options(widgetId, "calendar")
        val today = LocalDate.now()
        val month = YearMonth.from(today)
        val foreground = Color.parseColor(if (options.dark) "#F3F4F6" else "#111827")
        val muted = Color.parseColor(if (options.dark) "#CBD5E1" else "#6B7280")
        val surface = Color.parseColor(if (options.dark) "#182337" else "#FFFFFF")
        views.setInt(R.id.calendar_surface, "setBackgroundColor",
            (surface and 0x00ffffff) or ((options.opacity.coerceIn(20, 100) * 255 / 100) shl 24))
        views.setTextViewText(R.id.calendar_month, "${month.year}년 ${month.monthValue}월")
        views.setTextColor(R.id.calendar_month, foreground)
        views.setTextViewText(R.id.calendar_today, "오늘 ${today.dayOfMonth}일")
        views.setTextColor(R.id.calendar_empty, muted)
        val expand = WidgetWorkspaceActivity.pending(context, "calendar", widgetId = widgetId, kind = "calendar",
            selectedDate = today.toString())
        views.setOnClickPendingIntent(R.id.calendar_surface, expand)
        views.setOnClickPendingIntent(R.id.calendar_header, expand)
        views.removeAllViews(R.id.calendar_weeks)
        try {
            val tasks = WidgetTaskPolicy.select(store.tasks(), options.copy(period = "all"),
                System.currentTimeMillis() / 1000, store.pins())
            val byDate = tasks.filter { it.due != null }.groupBy {
                Instant.ofEpochSecond(it.due!!).atZone(ZoneId.systemDefault()).toLocalDate()
            }
            val height = manager.getAppWidgetOptions(widgetId).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 320)
            // Six rows also cover months beginning on Saturday without clipping the final week.
            val tall = height >= 350
            val first = month.atDay(1)
            val start = first.minusDays((first.dayOfWeek.value % 7).toLong())
            for (week in 0 until 6) {
                val row = RemoteViews(context.packageName, if (tall) R.layout.widget_calendar_week_large else R.layout.widget_calendar_week)
                for (day in 0 until 7) {
                    val date = start.plusDays((week * 7 + day).toLong())
                    val matches = byDate[date].orEmpty()
                    val cell = RemoteViews(context.packageName, R.layout.widget_calendar_day)
                    cell.setTextViewText(R.id.calendar_day_number, date.dayOfMonth.toString())
                    val currentMonth = YearMonth.from(date) == month
                    cell.setTextColor(R.id.calendar_day_number, when {
                        date == today -> Color.WHITE
                        !currentMonth -> if (options.dark) Color.parseColor("#778398") else Color.parseColor("#9CA3AF")
                        day == 0 -> Color.parseColor(if (options.dark) "#FDA4AF" else "#D95D69")
                        else -> foreground
                    })
                    cell.setTextViewTextSize(R.id.calendar_day_number, android.util.TypedValue.COMPLEX_UNIT_SP,
                        if (options.largeText) 16f else 14f)
                    cell.setInt(R.id.calendar_day_number, "setBackgroundResource",
                        if (date == today) R.drawable.widget_calendar_today else android.R.color.transparent)
                    cell.setViewVisibility(R.id.calendar_day_dot, if (matches.isEmpty()) View.INVISIBLE else View.VISIBLE)
                    cell.setTextColor(R.id.calendar_day_dot,
                        if (matches.any { !it.completed }) Color.parseColor(if (options.dark) "#93C5FD" else "#1262D6") else muted)
                    cell.setContentDescription(R.id.calendar_day_cell,
                        "${date.monthValue}월 ${date.dayOfMonth}일, 일정 ${matches.size}개. 날짜별 일정 확대")
                    cell.setOnClickPendingIntent(R.id.calendar_day_cell, WidgetWorkspaceActivity.pending(context,
                        "calendar", widgetId = widgetId, kind = "calendar", selectedDate = date.toString()))
                    row.addView(R.id.calendar_week_cells, cell)
                }
                views.addView(R.id.calendar_weeks, row)
            }
            views.setViewVisibility(R.id.calendar_empty, View.GONE)
        } catch (error: Exception) {
            views.setViewVisibility(R.id.calendar_empty, View.VISIBLE)
            views.setTextViewText(R.id.calendar_empty, error.message ?: "일정을 불러오지 못했습니다.")
        }
        manager.updateAppWidget(widgetId, views)
    }
}

package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Color
import android.view.View
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/** A quiet month grid; management lives in the floating calendar workspace. */
object WidgetCalendarRenderer {
    fun render(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val dimensions = manager.getAppWidgetOptions(widgetId)
        if (Build.VERSION.SDK_INT >= 31) {
            val sizes = androidx.core.os.BundleCompat.getParcelableArrayList(dimensions,
                AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java)?.filter { it.width > 0 && it.height > 0 }?.distinct()?.take(16)
            if (!sizes.isNullOrEmpty()) {
                val variants = sizes.associateWith { createViews(context, widgetId, it.width.toInt(), it.height.toInt()) }
                manager.updateAppWidget(widgetId, if (variants.size == 1) variants.values.first() else RemoteViews(variants))
                return
            }
        }
        manager.updateAppWidget(widgetId, createViews(context, widgetId,
            dimensions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 300),
            dimensions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 340)))
    }

    fun createViews(context: Context, widgetId: Int, width: Int, height: Int): RemoteViews {
        val store = WidgetTaskStore(context)
        val options = store.options(widgetId, "calendar")
        val today = LocalDate.now()
        val month = YearMonth.from(today)
        val layout = WidgetCalendarLayout.forSize(today, width, height)
        val views = RemoteViews(context.packageName, if (layout.compact) R.layout.widget_calendar_compact else R.layout.widget_calendar)
        val palette = WidgetPalette.from(options)
        val foreground = palette.text
        val muted = palette.muted
        views.setInt(R.id.widget_card_background, "setColorFilter", palette.surface)
        views.setInt(R.id.widget_card_background, "setImageAlpha", Color.alpha(palette.surfaceWithOpacity(options.opacity)))
        views.setTextViewText(R.id.calendar_month, if (width < 240) "${month.monthValue}월" else "${month.year}년 ${month.monthValue}월")
        views.setTextColor(R.id.calendar_month, foreground)
        views.setTextViewText(R.id.calendar_today, if (width < 180) "${today.dayOfMonth}일" else "오늘 ${today.dayOfMonth}일")
        views.setTextColor(R.id.calendar_today, palette.accent)
        views.setTextColor(R.id.calendar_empty, muted)
        for ((index, id) in listOf(R.id.calendar_sun, R.id.calendar_mon, R.id.calendar_tue, R.id.calendar_wed,
                R.id.calendar_thu, R.id.calendar_fri, R.id.calendar_sat).withIndex()) {
            views.setTextColor(id, if (index == 0) palette.red else if (index == 6) palette.accent else muted)
            views.setTextViewTextSize(id, android.util.TypedValue.COMPLEX_UNIT_SP, if (width < 180) 9f else 11f)
        }
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
            for (week in 0 until layout.weeks) {
                val row = RemoteViews(context.packageName, R.layout.widget_calendar_week)
                for (day in 0 until 7) {
                    val date = layout.start.plusDays((week * 7 + day).toLong())
                    val matches = byDate[date].orEmpty()
                    val cell = RemoteViews(context.packageName, when {
                        layout.showTitles -> R.layout.widget_calendar_day_event
                        layout.compact -> R.layout.widget_calendar_day_compact
                        else -> R.layout.widget_calendar_day
                    })
                    cell.setTextViewText(R.id.calendar_day_number, date.dayOfMonth.toString())
                    val currentMonth = YearMonth.from(date) == month
                    cell.setTextColor(R.id.calendar_day_number, when {
                        date == today -> Color.WHITE
                        !currentMonth -> palette.outside
                        day == 0 -> palette.red
                        day == 6 -> palette.accent
                        else -> foreground
                    })
                    cell.setTextViewTextSize(R.id.calendar_day_number, android.util.TypedValue.COMPLEX_UNIT_SP,
                        if (width < 180) 11f else if (layout.compact) 12f else if (options.largeText) 16f else 14f)
                    cell.setInt(R.id.calendar_day_number, "setBackgroundResource",
                        if (date == today) R.drawable.widget_calendar_today else android.R.color.transparent)
                    cell.setViewVisibility(R.id.calendar_day_dot, if (layout.showTitles) View.GONE else if (matches.isEmpty()) View.INVISIBLE else View.VISIBLE)
                    cell.setTextColor(R.id.calendar_day_dot,
                        if (matches.any { !it.completed }) palette.accent else muted)
                    if (layout.showTitles) {
                        cell.setViewVisibility(R.id.calendar_day_event_group, if (matches.isEmpty()) View.INVISIBLE else View.VISIBLE)
                        cell.setTextViewText(R.id.calendar_day_event, matches.firstOrNull()?.title ?: "")
                        cell.setInt(R.id.calendar_day_event, "setMaxLines", if (matches.size > 1) 1 else 2)
                        cell.setTextColor(R.id.calendar_day_event, foreground)
                        cell.setInt(R.id.calendar_event_bar, "setBackgroundColor", palette.accent)
                        cell.setViewVisibility(R.id.calendar_day_extra, if (matches.size > 1) View.VISIBLE else View.GONE)
                        cell.setTextViewText(R.id.calendar_day_extra, "+${matches.size - 1}")
                        cell.setTextColor(R.id.calendar_day_extra, muted)
                    }
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
        return views
    }
}

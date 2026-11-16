package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONException
import org.json.JSONObject
import java.time.LocalDate

class CalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        WidgetDateRefresh.schedule(context)
        WidgetDateRefresh.request(context)
        val days = readDays(widgetData)
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id, appWidgetManager.getAppWidgetOptions(id), days)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        render(context, manager, id, options, readDays(HomeWidgetPlugin.getData(context)))
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetDateRefresh.schedule(context)
    }

    private fun readDays(prefs: SharedPreferences): JSONObject {
        val raw = prefs.getString(STORAGE_KEY, null) ?: return JSONObject()
        return try {
            JSONObject(raw)
        } catch (_: JSONException) {
            JSONObject()
        }
    }

    private fun render(context: Context, manager: AppWidgetManager, id: Int, options: Bundle, days: JSONObject) {
        val size = WidgetSize.from(context, options, defaultWidth = 276, defaultHeight = 340)
        manager.updateAppWidget(id, createViews(context, size, LocalDate.now(), days))
    }

    internal fun createViews(context: Context, size: WidgetSize, today: LocalDate, days: JSONObject): RemoteViews {
        val layout = WidgetCalendarLayout.forSize(today, size)
        val views = RemoteViews(context.packageName, R.layout.widget_calendar)
        val openCalendar = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("kutodo://widget/calendar"),
        )
        views.setOnClickPendingIntent(R.id.widget_calendar_root, openCalendar)
        views.setTextViewText(
            R.id.widget_calendar_month,
            context.getString(R.string.widget_calendar_month_format, today.year.toString(), today.monthValue),
        )
        views.removeAllViews(R.id.widget_calendar_weeks)
        for (week in 0 until layout.weeks) {
            val row = RemoteViews(context.packageName, R.layout.widget_calendar_week)
            for (day in 0 until 7) {
                val date = layout.start.plusDays((week * 7 + day).toLong())
                row.addView(R.id.widget_calendar_week, dayView(context, date, today, days, layout.showTitles))
            }
            views.addView(R.id.widget_calendar_weeks, row)
        }
        return views
    }

    private fun dayView(
        context: Context,
        date: LocalDate,
        today: LocalDate,
        days: JSONObject,
        showTitles: Boolean,
    ): RemoteViews {
        val events = days.optJSONObject(date.toString())
        val count = events?.optInt("count") ?: 0
        val title = events?.optString("title").orEmpty()
        val cell = RemoteViews(context.packageName, R.layout.widget_calendar_day)
        cell.setTextViewText(R.id.widget_calendar_day_number, date.dayOfMonth.toString())
        val dateColor = when {
            date == today -> R.color.widget_primary
            date.month != today.month -> R.color.widget_muted
            else -> R.color.widget_ink
        }
        cell.setTextColor(R.id.widget_calendar_day_number, context.getColor(dateColor))
        if (date == today) {
            cell.setInt(R.id.widget_calendar_day_number, "setBackgroundResource", R.drawable.widget_calendar_today)
        }
        if (count > 0) {
            cell.setViewVisibility(R.id.widget_calendar_event, View.VISIBLE)
            cell.setTextViewText(R.id.widget_calendar_event, if (showTitles && title.isNotBlank()) title else "•")
            cell.setContentDescription(
                R.id.widget_calendar_event,
                context.getString(R.string.widget_calendar_day_events, date.monthValue, date.dayOfMonth, count),
            )
        }
        return cell
    }

    private companion object {
        const val STORAGE_KEY = "calendar_widget_data"
    }
}

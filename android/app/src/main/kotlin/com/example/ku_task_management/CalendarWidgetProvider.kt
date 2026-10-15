package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class CalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { WidgetCalendarRenderer.render(context, appWidgetManager, it) }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        WidgetCalendarRenderer.render(context, manager, id)
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        val editor = HomeWidgetPlugin.getData(context).edit()
        ids.forEach { editor.remove("workspace_options_$it") }
        editor.apply()
    }
}

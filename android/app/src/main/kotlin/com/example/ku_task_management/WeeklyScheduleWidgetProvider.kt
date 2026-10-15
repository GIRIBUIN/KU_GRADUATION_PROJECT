package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetProvider

class WeeklyScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { WidgetWorkspaceRenderer.render(context, appWidgetManager, it, "weekly") }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        WidgetWorkspaceRenderer.render(context, manager, id, "weekly")
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        val editor = es.antonborri.home_widget.HomeWidgetPlugin.getData(context).edit()
        ids.forEach { editor.remove("workspace_options_$it") }
        editor.apply()
    }

    companion object {
        fun requestUpdate(context: Context) = WidgetWorkspaceRenderer.refreshAll(context)
    }
}

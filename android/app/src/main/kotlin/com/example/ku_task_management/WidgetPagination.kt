package com.example.ku_task_management

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

object WidgetPagination {
    private const val ACTION = "com.example.ku_task_management.WIDGET_PAGE"
    private fun key(id: Int) = "widget_page_$id"

    fun page(prefs: SharedPreferences, id: Int, size: Int, pageSize: Int): WidgetPage {
        val page = widgetPage(size, pageSize, prefs.getInt(key(id), 0))
        prefs.edit().putInt(key(id), page.index).apply()
        return page
    }

    fun delete(prefs: SharedPreferences, ids: IntArray) {
        val editor = prefs.edit()
        ids.forEach { editor.remove(key(it)) }
        editor.apply()
    }

    fun receive(context: Context, intent: Intent, provider: Class<*>, prefs: SharedPreferences): Int? {
        if (intent.action != ACTION) return null
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        val manager = AppWidgetManager.getInstance(context)
        if (manager.getAppWidgetInfo(id)?.provider != ComponentName(context, provider)) return null
        val target = intent.getIntExtra("page", 0).coerceAtLeast(0)
        prefs.edit().putInt(key(id), target).apply()
        return id
    }

    fun bind(context: Context, views: RemoteViews, provider: Class<*>, id: Int, page: WidgetPage, empty: Boolean) {
        views.setTextViewText(R.id.widget_page, if (empty) "0/0" else "${page.index + 1}/${page.count}")
        views.setViewVisibility(R.id.widget_empty, if (empty) View.VISIBLE else View.GONE)
        listOf(Triple(R.id.widget_previous, page.index - 1, !empty && page.index > 0),
            Triple(R.id.widget_next, page.index + 1, !empty && page.index + 1 < page.count)).forEach { (view, target, enabled) ->
            views.setBoolean(view, "setEnabled", enabled)
            // View.setAlpha is not a RemoteViews action; dim the button text instead.
            val color = context.getColor(R.color.widget_muted)
            views.setTextColor(view, if (enabled) color else Color.argb(77, Color.red(color), Color.green(color), Color.blue(color)))
            val intent = Intent(context, provider).apply {
                action = ACTION
                data = Uri.parse("kutodo://widget/$id/page/$target")
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                putExtra("page", target)
            }
            views.setOnClickPendingIntent(view, PendingIntent.getBroadcast(context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        }
    }
}

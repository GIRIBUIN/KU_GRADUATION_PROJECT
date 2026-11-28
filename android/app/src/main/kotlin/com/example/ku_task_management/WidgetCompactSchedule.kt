package com.example.ku_task_management

import android.app.PendingIntent
import android.content.Context
import android.graphics.Paint
import android.view.View
import android.widget.RemoteViews

internal fun RemoteViews.bindCompactSchedule(
    context: Context,
    header: Int,
    title: String?,
    completed: Boolean,
    toggle: PendingIntent?,
) {
    setTextViewText(R.id.widget_title, context.getText(header))
    setViewVisibility(R.id.task_row_0, if (title == null) View.GONE else View.VISIBLE)
    setTextViewText(R.id.task_title_0, title.orEmpty())
    setTextColor(R.id.task_title_0, context.getColor(if (completed) R.color.widget_muted else R.color.widget_ink))
    setInt(R.id.task_title_0, "setPaintFlags", Paint.ANTI_ALIAS_FLAG or
        if (completed) Paint.STRIKE_THRU_TEXT_FLAG else 0)
    setImageViewResource(R.id.task_checkbox_0, if (completed)
        R.drawable.widget_checkbox_checked else R.drawable.widget_checkbox_unchecked)
    setOnClickPendingIntent(R.id.task_row_0, toggle)
    setOnClickPendingIntent(R.id.task_checkbox_0, toggle)
}

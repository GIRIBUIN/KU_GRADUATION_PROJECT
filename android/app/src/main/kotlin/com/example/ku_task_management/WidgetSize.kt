package com.example.ku_task_management

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import kotlin.math.ceil

internal data class WidgetSize(val width: Int, val height: Int, val fontScale: Float) {
    fun rows(reservedHeight: Int, rowHeight: Int, maximum: Int): Int {
        val scale = fontScale.coerceAtLeast(1f)
        val available = height - ceil(reservedHeight * scale).toInt()
        return (available / ceil(rowHeight * scale).toInt()).coerceIn(1, maximum)
    }

    companion object {
        fun from(context: Context, options: Bundle, defaultWidth: Int, defaultHeight: Int): WidgetSize =
            WidgetSize(
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: defaultWidth,
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT).takeIf { it > 0 } ?: defaultHeight,
                context.resources.configuration.fontScale,
            )
    }
}

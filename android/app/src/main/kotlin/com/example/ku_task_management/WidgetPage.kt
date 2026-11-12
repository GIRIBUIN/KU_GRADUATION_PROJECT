package com.example.ku_task_management

/** Zero-based page math, shared by both RemoteViews providers. */
data class WidgetPage(val index: Int, val count: Int, val start: Int, val end: Int)

fun widgetPage(size: Int, pageSize: Int, requested: Int): WidgetPage {
    require(size >= 0 && pageSize > 0)
    val count = maxOf(1, (size + pageSize - 1) / pageSize)
    val index = requested.coerceIn(0, count - 1)
    val start = index * pageSize
    return WidgetPage(index, count, start, minOf(size, start + pageSize))
}


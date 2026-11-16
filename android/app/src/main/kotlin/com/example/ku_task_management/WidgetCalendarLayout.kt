package com.example.ku_task_management

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.time.temporal.TemporalAdjusters

internal data class WidgetCalendarLayout(
    val start: LocalDate,
    val weeks: Int,
    val showTitles: Boolean,
    val inlineEvents: Boolean,
) {
    companion object {
        fun forSize(today: LocalDate, size: WidgetSize): WidgetCalendarLayout {
            val first = today.withDayOfMonth(1)
            val monthStart = first.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            val totalWeeks = ((first.dayOfWeek.value - 1) + first.lengthOfMonth() + 6) / 7
            val scale = size.fontScale.coerceAtLeast(1f)
            val inlineEvents = size.height < (80 + totalWeeks * 32) * scale
            val rowHeight = if (inlineEvents) 16 else 32
            val weeks = size.rows(reservedHeight = 80, rowHeight = rowHeight, maximum = totalWeeks)
            val currentWeek = (ChronoUnit.DAYS.between(monthStart, today) / 7).toInt()
            val offset = (currentWeek - (weeks - 1) / 2).coerceIn(0, totalWeeks - weeks)
            val showTitles = !inlineEvents && size.width >= 280 * scale && size.height >= (80 + weeks * 39) * scale
            return WidgetCalendarLayout(monthStart.plusWeeks(offset.toLong()), weeks, showTitles, inlineEvents)
        }
    }
}

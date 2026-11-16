package com.example.ku_task_management

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.time.temporal.TemporalAdjusters

internal data class WidgetCalendarLayout(
    val start: LocalDate,
    val weeks: Int,
    val showTitles: Boolean,
) {
    companion object {
        fun forSize(today: LocalDate, size: WidgetSize): WidgetCalendarLayout {
            val first = today.withDayOfMonth(1)
            val monthStart = first.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            val totalWeeks = ((first.dayOfWeek.value - 1) + first.lengthOfMonth() + 6) / 7
            val weeks = size.rows(reservedHeight = 72, rowHeight = 27, maximum = totalWeeks)
            val currentWeek = (ChronoUnit.DAYS.between(monthStart, today) / 7).toInt()
            val offset = (currentWeek - (weeks - 1) / 2).coerceIn(0, totalWeeks - weeks)
            val scale = size.fontScale.coerceAtLeast(1f)
            val showTitles = size.width >= 280 * scale && size.height >= (72 + weeks * 39) * scale
            return WidgetCalendarLayout(monthStart.plusWeeks(offset.toLong()), weeks, showTitles)
        }
    }
}

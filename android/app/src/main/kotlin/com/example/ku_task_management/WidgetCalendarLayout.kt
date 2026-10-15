package com.example.ku_task_management

import java.time.LocalDate
import java.time.YearMonth
import java.time.temporal.ChronoUnit

data class WidgetCalendarLayout(val start: LocalDate, val weeks: Int, val compact: Boolean, val showTitles: Boolean) {
    companion object {
        fun forSize(today: LocalDate, width: Int, height: Int): WidgetCalendarLayout {
            val month = YearMonth.from(today)
            val first = month.atDay(1)
            val start = first.minusDays((first.dayOfWeek.value % 7).toLong())
            val total = ((first.dayOfWeek.value % 7 + month.lengthOfMonth() + 6) / 7)
            val compact = width < 260 || height < 260
            val titles = width >= 280
            // Keep the row budget independent of the visual header breakpoint so growing never removes a week.
            val reserved = if (width < 260) 58 else 94
            val weeks = ((height - reserved) / if (titles) 46 else 28).coerceIn(1, total)
            val current = (ChronoUnit.DAYS.between(start, today) / 7).toInt()
            val offset = (current - (weeks - 1) / 2).coerceIn(0, total - weeks)
            return WidgetCalendarLayout(start.plusWeeks(offset.toLong()), weeks, compact,
                titles && (height - reserved) / weeks >= 46)
        }
    }
}

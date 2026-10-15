package com.example.ku_task_management

import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test

class WidgetCalendarLayoutTest {
    @Test fun everyMonthAndSizeKeepsTodayAndEndsWithOneCompleteWeek() {
        for (year in 2024..2027) for (month in 1..12) for (day in listOf(1, 15, 28)) {
            val today = LocalDate.of(year, month, day)
            for (width in listOf(140, 220, 360)) {
                val layouts = (96..500).map { WidgetCalendarLayout.forSize(today, width, it) }
                assertEquals(1, layouts.first().weeks)
                layouts.forEach {
                    assertEquals(java.time.DayOfWeek.SUNDAY, it.start.dayOfWeek)
                    assertFalse(today.isBefore(it.start))
                    assertTrue(today.isBefore(it.start.plusWeeks(it.weeks.toLong())))
                }
                assertEquals(layouts.map { it.weeks }.sorted(), layouts.map { it.weeks })
                val full = layouts.last()
                assertFalse(today.withDayOfMonth(1).isBefore(full.start))
                assertTrue(today.withDayOfMonth(today.lengthOfMonth()).isBefore(full.start.plusWeeks(full.weeks.toLong())))
            }
        }
    }

    @Test fun wideCalendarsShowTitlesAndNarrowCalendarsKeepDates() {
        val today = LocalDate.of(2026, 10, 15)
        assertTrue(WidgetCalendarLayout.forSize(today, 360, 340).showTitles)
        assertFalse(WidgetCalendarLayout.forSize(today, 220, 340).showTitles)
        assertFalse(WidgetCalendarLayout.forSize(today, 360, 96).showTitles)
    }
}

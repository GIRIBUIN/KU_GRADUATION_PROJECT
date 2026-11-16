package com.example.ku_task_management

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class WidgetResizeTest {
    @Test
    fun listWidgetsReduceRowsAndKeepTheUsualPageCapacityAtDefaultSize() {
        assertEquals(1, WidgetSize(160, 152, 1f).rows(94, 45, 3))
        assertEquals(3, WidgetSize(240, 250, 1f).rows(94, 45, 3))
        assertEquals(1, WidgetSize(160, 180, 1f).rows(118, 41, 5))
        assertEquals(5, WidgetSize(276, 340, 1f).rows(118, 41, 5))
    }

    @Test
    fun calendarScalesFromCurrentWeeksWithDotsToFullMonthWithTitles() {
        val context = RuntimeEnvironment.getApplication()
        val today = LocalDate.of(2026, 8, 29)
        val events = JSONObject("""{"2026-08-29":{"title":"Capstone meeting","count":1}}""")

        assertCalendar(context, today, events, WidgetSize(168, 128, 1f), 2, "•")
        assertCalendar(context, today, events, WidgetSize(340, 340, 1f), 6, "Capstone meeting")
    }

    private fun assertCalendar(
        context: Context,
        today: LocalDate,
        events: JSONObject,
        size: WidgetSize,
        expectedWeeks: Int,
        expectedEventLabel: String,
    ) {
        val view = CalendarWidgetProvider().createViews(context, size, today, events)
            .apply(context, FrameLayout(context))
        val rows = view.findViewById<LinearLayout>(R.id.widget_calendar_weeks)
        assertEquals(expectedWeeks, rows.childCount)
        val layout = WidgetCalendarLayout.forSize(today, size)
        val offset = ChronoUnit.DAYS.between(layout.start, today).toInt()
        val row = rows.getChildAt(offset / 7) as LinearLayout
        assertEquals(7, row.childCount)
        val eventCell = row.getChildAt(offset % 7)
        val event = eventCell.findViewById<TextView>(R.id.widget_calendar_event)
        assertEquals(View.VISIBLE, event.visibility)
        assertEquals(expectedEventLabel, event.text.toString())

        val density = context.resources.displayMetrics.density
        val width = (size.width * density).toInt()
        val height = (size.height * density).toInt()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
        assertTrue(row.height > 0)
        assertTrue(event.height > 0 && event.bottom <= eventCell.height)
    }
}

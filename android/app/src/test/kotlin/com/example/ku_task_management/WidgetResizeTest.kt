package com.example.ku_task_management

import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.graphics.Paint
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.RemoteViews
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.xmlpull.v1.XmlPullParser
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WidgetResizeTest {
    @Test
    fun listWidgetsShowMoreRowsWhenExpanded() {
        assertEquals(1, WidgetSize(160, 152, 1f).rows(94, 45, 3))
        assertEquals(3, WidgetSize(240, 250, 1f).rows(94, 45, 3))
        assertEquals(1, WidgetSize(160, 180, 1f).rows(118, 41, 5))
        assertEquals(5, WidgetSize(276, 340, 1f).rows(118, 41, 5))
    }

    @Test
    @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun calendarScalesFromCurrentWeeksWithDotsToFullMonthWithTitles() {
        val context = RuntimeEnvironment.getApplication()
        val today = LocalDate.of(2026, 8, 29)
        val events = JSONObject("""{"2026-08-29":{"title":"Capstone meeting","count":1}}""")

        assertCalendar(context, today, events, WidgetSize(168, 110, 1f), 1, null)
        assertCalendar(context, today, events, WidgetSize(250, 180, 1f), 6, null)
        assertCalendar(context, today, events, WidgetSize(340, 340, 1f), 6, "Capstone meeting")
    }

    @Test
    fun allProvidersDefaultToFourByThreeAndCanResizeBothWays() {
        val context = RuntimeEnvironment.getApplication()
        val resources = context.resources
        val android = "http://schemas.android.com/apk/res/android"
        for (id in listOf(R.xml.schedule_widget_info, R.xml.weekly_schedule_widget_info, R.xml.calendar_widget_info)) {
            resources.getXml(id).use { xml ->
                var event = xml.eventType
                while (event != XmlPullParser.START_TAG && event != XmlPullParser.END_DOCUMENT) {
                    event = xml.next()
                }
                assertEquals(XmlPullParser.START_TAG, event)
                assertEquals(4, xml.getAttributeIntValue(android, "targetCellWidth", -1))
                assertEquals(3, xml.getAttributeIntValue(android, "targetCellHeight", -1))
                assertEquals(
                    AppWidgetProviderInfo.RESIZE_BOTH, xml.getAttributeIntValue(android, "resizeMode", -1),
                )
            }
        }
    }

    @Test
    @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun compactListKeepsTheTaskAndPageButtonsAtMinimumSize() {
        val context = RuntimeEnvironment.getApplication()
        val views = RemoteViews(context.packageName, R.layout.widget_schedule_compact)
        views.bindCompactSchedule(context, R.string.schedule_widget_header_title, "Assignment", false, null)
        val root = views.apply(context, FrameLayout(context))
        val density = context.resources.displayMetrics.density
        val width = (160 * density).toInt()
        val height = (110 * density).toInt()
        root.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        root.layout(0, 0, width, height)
        val task = root.findViewById<TextView>(R.id.task_title_0)
        val row = root.findViewById<View>(R.id.task_row_0)
        assertEquals("Assignment", task.text.toString())
        assertTrue(task.height > 0 && task.bottom <= row.height)
        assertTrue(root.findViewById<View>(R.id.widget_next).height > 0)
    }

    private fun assertCalendar(
        context: Context,
        today: LocalDate,
        events: JSONObject,
        size: WidgetSize,
        expectedWeeks: Int,
        expectedEventLabel: String?,
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
        val marker = if (expectedEventLabel == null) {
            assertEquals(View.GONE, event.visibility)
            eventCell.findViewById<TextView>(R.id.widget_calendar_day_number).also {
                assertTrue((it.paintFlags and Paint.UNDERLINE_TEXT_FLAG) != 0)
            }
        } else {
            assertEquals(View.VISIBLE, event.visibility)
            assertEquals(expectedEventLabel, event.text.toString())
            event
        }

        val density = context.resources.displayMetrics.density
        val width = (size.width * density).toInt()
        val height = (size.height * density).toInt()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
        assertTrue(row.height > 0)
        assertTrue(
            "At ${size.width}x${size.height}, event bottom=${marker.bottom}, " +
                "event height=${marker.height}, cell height=${eventCell.height}",
            marker.height > 0 && marker.bottom <= eventCell.height,
        )
    }
}

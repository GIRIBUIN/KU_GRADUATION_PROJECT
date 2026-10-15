package com.example.ku_task_management

import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId

class WidgetTaskPolicyTest {
    @Test fun reminderCompatibilityMatchesTheDriftMapper() {
        assertEquals(1440, WidgetTaskPolicy.reminderMinutes(1, "09:00"))
        assertEquals(60, WidgetTaskPolicy.reminderMinutes(60, "relative"))
        assertEquals(60, WidgetTaskPolicy.reminderMinutes(60, "09:00"))
        assertEquals(30, WidgetTaskPolicy.reminderMinutes(30, null))
    }
    private val zone = ZoneId.of("Asia/Seoul")
    private val now = time(15, 12)
    private fun time(day: Int, hour: Int = 23) = LocalDateTime.of(2026, 10, day, hour, 0).atZone(zone).toEpochSecond()
    private fun task(id: String, day: Int? = 15, status: String = "active", origin: String = "personal",
                     priority: String? = null, tags: Set<String> = emptySet(), folders: Set<String> = emptySet()) =
        WidgetTask(id, id, origin, status, day?.let { time(it) }, priority, "", "", null, 0, tags, folders)

    @Test fun todayRetainsOverdueItemsFromEarlierToday() {
        val overdue = task("overdue").copy(due = time(15, 9))
        assertEquals(listOf("overdue", "later"), WidgetTaskPolicy.select(
            listOf(task("tomorrow", 16), task("later"), overdue), WidgetOptions(), now, zone = zone).map { it.id })
    }

    @Test fun deletedAndExcludedNeverLeakIntoRegularViews() {
        val items = listOf(task("active"), task("done", status = "completed"), task("deleted", status = "deleted"),
            task("excluded", status = "excluded", origin = "ecampus"))
        assertEquals(listOf("active"), WidgetTaskPolicy.select(items, WidgetOptions(period = "all"), now, zone = zone).map { it.id })
        assertEquals(setOf("deleted", "excluded"), WidgetTaskPolicy.select(items, WidgetOptions(period = "trash"), now, zone = zone).map { it.id }.toSet())
    }

    @Test fun weekCrossesMonthAndUsesLocalCalendarDays() {
        val monday = LocalDateTime.of(2026, 11, 2, 0, 1).atZone(zone).toEpochSecond()
        val sunday = task("previousSunday").copy(due = monday - 120)
        val nextSunday = task("nextSunday").copy(due = monday + 6 * 86400)
        assertEquals(listOf("nextSunday"), WidgetTaskPolicy.select(listOf(sunday, nextSunday),
            WidgetOptions(period = "week"), monday, zone = zone).map { it.id })
    }

    @Test fun combinesOriginTagAndFolderFilters() {
        val matched = task("match", origin = "ecampus", tags = setOf("course"), folders = setOf("school"))
        val options = WidgetOptions(period = "all", origin = "ecampus", tag = "course", folder = "school")
        assertEquals(listOf(matched), WidgetTaskPolicy.select(listOf(task("other"), matched,
            matched.copy(id = "wrongFolder", folders = setOf("personal"))), options, now, zone = zone))
    }

    @Test fun completionAndPinAndPrioritySortAreDeterministic() {
        val items = listOf(task("done", status = "completed"), task("low", priority = "low"),
            task("high", priority = "high"), task("pin", priority = "low"))
        assertEquals(listOf("pin", "high", "low", "done"), WidgetTaskPolicy.select(items,
            WidgetOptions(period = "all", sort = "priority", showCompleted = true), now, setOf("pin"), zone = zone).map { it.id })
    }

    @Test fun undatedTasksRemainAvailableInAllView() {
        val item = task("noDue", null)
        assertTrue(WidgetTaskPolicy.select(listOf(item), WidgetOptions(), now, zone = zone).isEmpty())
        assertEquals(listOf(item), WidgetTaskPolicy.select(listOf(item), WidgetOptions(period = "all"), now, zone = zone))
    }

    @Test fun urgentWindowExcludesPastAndIncludesLastDay() {
        val items = listOf(task("past", 14), task("today"), task("lastDay", 18), task("later", 19))
        assertEquals(listOf("today", "lastDay"), WidgetTaskPolicy.select(items,
            WidgetOptions(period = "urgent"), now, zone = zone).map { it.id })
    }

    @Test(expected = IllegalArgumentException::class)
    fun academicDeadlineCannotBePostponed() { WidgetTaskPolicy.postponedDue(task("school", origin = "ecampus"), 1) }

    @Test(expected = IllegalArgumentException::class)
    fun undatedTaskCannotBePostponed() { WidgetTaskPolicy.postponedDue(task("undated", null), 1) }
}

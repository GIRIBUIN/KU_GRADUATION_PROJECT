package com.example.ku_task_management

import android.app.AlarmManager
import android.app.job.JobScheduler
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Looper
import org.robolectric.shadows.ShadowAlarmManager
import es.antonborri.home_widget.HomeWidgetPlugin
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.ZonedDateTime
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class WidgetDateRefreshTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private val scheduler get() = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
    private val alarms get() = shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)

    @Before fun reset() { HomeWidgetPlugin.getData(context).edit().clear().commit() }

    private fun install(weekly: Boolean = false) {
        val provider = if (weekly) WeeklyScheduleWidgetProvider::class.java else ScheduleWidgetProvider::class.java
        shadowOf(AppWidgetManager.getInstance(context)).bindAppWidgetId(101, ComponentName(context, provider))
    }

    @Test fun nextMidnightUsesCalendarDateAcrossWeekYearAndDst() {
        for ((now, expected) in listOf(
            "2026-11-15T23:59:59+09:00[Asia/Seoul]" to "2026-11-16T00:00:00+09:00[Asia/Seoul]",
            "2026-12-31T12:00:00+09:00[Asia/Seoul]" to "2027-01-01T00:00:00+09:00[Asia/Seoul]",
            "2026-03-08T00:00:00-05:00[America/New_York]" to "2026-03-09T00:00:00-04:00[America/New_York]",
            "2026-11-01T00:00:00-04:00[America/New_York]" to "2026-11-02T00:00:00-05:00[America/New_York]"
        )) {
            val date = ZonedDateTime.parse(now)
            assertEquals(ZonedDateTime.parse(expected).toInstant().toEpochMilli(),
                WidgetDateRefresh.nextMidnight(date.toInstant().toEpochMilli(), TimeZone.getTimeZone(date.zone)))
        }
    }

    @Test fun weeklyWidgetAloneSchedulesOneMidnightAlarmAndDeduplicatedJob() {
        install(weekly = true)
        WidgetDateRefresh.schedule(context)
        WidgetDateRefresh.schedule(context)
        assertEquals(1, alarms.scheduledAlarms.size)
        assertEquals(0L, alarms.scheduledAlarms.single().windowLengthMs)
        assertTrue(alarms.scheduledAlarms.single().isAllowWhileIdle)
        assertEquals(AlarmManager.RTC_WAKEUP, alarms.scheduledAlarms.single().type)
        WidgetDateRefresh.request(context)
        WidgetDateRefresh.request(context)
        assertEquals(1, scheduler.allPendingJobs.size)
        assertEquals(WidgetDateRefreshJobService::class.java.name, scheduler.getPendingJob(WidgetDateRefresh.JOB_ID)!!.service.className)
    }

    @Test fun completedDaySkipsPeriodicRefreshButClockAndBootEventsForceRefresh() {
        install()
        val prefs = HomeWidgetPlugin.getData(context)
        prefs.edit().putString(WidgetDateRefresh.DATE_KEY, WidgetDateRefresh.dateKey()).commit()
        WidgetDateRefresh.request(context)
        assertNull(scheduler.getPendingJob(WidgetDateRefresh.JOB_ID))
        for (action in listOf(WidgetDateRefresh.ACTION, Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_MY_PACKAGE_REPLACED)) {
            WidgetDateRefreshReceiver().onReceive(context, Intent(action))
            assertNotNull(scheduler.getPendingJob(WidgetDateRefresh.JOB_ID))
            assertEquals(1, alarms.scheduledAlarms.size)
            scheduler.cancel(WidgetDateRefresh.JOB_ID)
        }
    }

    @Test fun naturalMidnightAlarmRequestsRefreshWithoutTimeChangedBroadcast() {
        install()
        ShadowAlarmManager.setAutoSchedule(false)
        val oldDay = WidgetDateRefresh.dateKey()
        HomeWidgetPlugin.getData(context).edit().putString(WidgetDateRefresh.DATE_KEY, oldDay).commit()
        WidgetDateRefresh.schedule(context)
        val midnightAlarm = alarms.scheduledAlarms.single()
        // Deliver the scheduled PendingIntent itself, with no TIME_SET / DATE_CHANGED.
        // Robolectric does not advance java.lang.System's wall clock here.
        alarms.fireAlarm(midnightAlarm)
        shadowOf(Looper.getMainLooper()).idle()
        assertNotNull(scheduler.getPendingJob(WidgetDateRefresh.JOB_ID))
        assertEquals(1, alarms.scheduledAlarms.size)
        assertEquals(WidgetDateRefresh.nextMidnight(System.currentTimeMillis()), alarms.scheduledAlarms.single().triggerAtMs)
        assertEquals(0L, alarms.scheduledAlarms.single().windowLengthMs)
    }

    @Test @Config(sdk = [31])
    fun permittedExactAlarmAndExpeditedJobAvoidNormalIdleDeferral() {
        install()
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        WidgetDateRefresh.schedule(context)
        assertEquals(0L, alarms.scheduledAlarms.single().windowLengthMs)
        WidgetDateRefresh.request(context)
        assertTrue(scheduler.getPendingJob(WidgetDateRefresh.JOB_ID)!!.isExpedited)
    }

    @Test @Config(sdk = [31])
    fun deniedExactAccessFallsBackAndGrantReschedulesExactMidnight() {
        install()
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        WidgetDateRefresh.schedule(context)
        assertNotEquals(0L, alarms.scheduledAlarms.single().windowLengthMs)
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        WidgetDateRefreshReceiver().onReceive(context,
            Intent(AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED))
        assertEquals(1, alarms.scheduledAlarms.size)
        assertEquals(0L, alarms.scheduledAlarms.single().windowLengthMs)
        assertNotNull(scheduler.getPendingJob(WidgetDateRefresh.JOB_ID))
    }

    @Test @Config(sdk = [31])
    fun exhaustedExpeditedQuotaStillQueuesFallbackJob() {
        install()
        shadowOf(scheduler).failExpeditedJob(true)
        WidgetDateRefresh.request(context)
        val job = scheduler.getPendingJob(WidgetDateRefresh.JOB_ID)!!
        assertFalse(job.isExpedited)
        assertEquals(0L, job.maxExecutionDelayMillis)
    }

    @Test fun noWidgetsMeansNoAlarmOrJobAndUnknownBroadcastDoesNothing() {
        WidgetDateRefreshReceiver().onReceive(context, Intent(WidgetDateRefresh.ACTION))
        assertTrue(alarms.scheduledAlarms.isEmpty())
        assertTrue(scheduler.allPendingJobs.isEmpty())
        install()
        WidgetDateRefreshReceiver().onReceive(context, Intent("unknown"))
        assertTrue(scheduler.allPendingJobs.isEmpty())
    }
}

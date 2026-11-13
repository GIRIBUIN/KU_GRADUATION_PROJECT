package com.example.ku_task_management

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import java.util.TimeZone

/** 날짜 갱신은 캐시 재표시가 아니라 기존 Dart Repository의 전체 조회를 실행한다. */
object WidgetDateRefresh {
    const val ACTION = "com.example.ku_task_management.WIDGET_MIDNIGHT"
    const val JOB_ID = 41072
    const val DATE_KEY = "widget_date_refresh_key"

    fun nextMidnight(now: Long, zone: TimeZone = TimeZone.getDefault()): Long =
        Calendar.getInstance(zone).apply {
            timeInMillis = now
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    fun dateKey(now: Long = System.currentTimeMillis()): String =
        Calendar.getInstance().apply { timeInMillis = now }.let {
            "${it.timeZone.id}:${it.get(Calendar.YEAR)}:${it.get(Calendar.DAY_OF_YEAR)}"
        }

    fun hasWidgets(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        return listOf(ScheduleWidgetProvider::class.java, WeeklyScheduleWidgetProvider::class.java)
            .any { manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty() }
    }

    private fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 0, Intent(context, WidgetDateRefreshReceiver::class.java).setAction(ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun schedule(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (!hasWidgets(context)) {
            alarm.cancel(alarmIntent(context))
            (context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler).cancel(JOB_ID)
            return
        }
        // 위젯은 정확한 알람 권한을 요구하지 않는다. Doze에서는 OS가 실행을 지연할 수 있다.
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,
            nextMidnight(System.currentTimeMillis()), alarmIntent(context))
    }

    fun request(context: Context, force: Boolean = false) {
        if (!hasWidgets(context)) return
        if (!force && HomeWidgetPlugin.getData(context).getString(DATE_KEY, null) == dateKey()) return
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        if (scheduler.getPendingJob(JOB_ID) != null) return
        scheduler.schedule(JobInfo.Builder(JOB_ID, ComponentName(context, WidgetDateRefreshJobService::class.java))
            .setOverrideDeadline(0).setBackoffCriteria(30_000L, JobInfo.BACKOFF_POLICY_EXPONENTIAL).build())
    }
}

class WidgetDateRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(WidgetDateRefresh.ACTION, Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED, Intent.ACTION_DATE_CHANGED,
                Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) return
        WidgetDateRefresh.schedule(context)
        WidgetDateRefresh.request(context, force = true)
    }
}

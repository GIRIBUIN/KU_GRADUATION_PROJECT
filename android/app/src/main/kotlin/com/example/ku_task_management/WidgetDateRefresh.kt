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
import android.os.Build
import android.util.Log
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
        val midnight = nextMidnight(System.currentTimeMillis())
        val operation = alarmIntent(context)
        // 일반 알람은 절전 상태에서 자정 이후로 밀린다. 허용된 기기는 정확한 알람을 쓴다.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarm.canScheduleExactAlarms()) {
            try {
                alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, midnight, operation)
                return
            } catch (_: SecurityException) {
                // 권한 확인과 예약 사이에 권한이 취소되어도 갱신 경로를 유지한다.
            }
        }
        Log.w("WidgetDateRefresh", "Exact alarm access unavailable; midnight refresh may be delayed")
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, midnight, operation)
    }

    fun request(context: Context, force: Boolean = false) {
        if (!hasWidgets(context)) return
        if (!force && HomeWidgetPlugin.getData(context).getString(DATE_KEY, null) == dateKey()) return
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        if (scheduler.getPendingJob(JOB_ID) != null) return
        val builder = JobInfo.Builder(JOB_ID, ComponentName(context, WidgetDateRefreshJobService::class.java))
            .setBackoffCriteria(30_000L, JobInfo.BACKOFF_POLICY_EXPONENTIAL)
        // 정확한 알람이 울려도 일반 Job은 Doze에서 대기할 수 있으므로 우선 실행한다.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (scheduler.schedule(builder.setExpedited(true).build()) == JobScheduler.RESULT_SUCCESS) return
            builder.setExpedited(false)
        }
        scheduler.schedule(builder.setOverrideDeadline(0).build())
    }
}

class WidgetDateRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(WidgetDateRefresh.ACTION, Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED, Intent.ACTION_DATE_CHANGED,
                Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
                AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED)) return
        WidgetDateRefresh.schedule(context)
        WidgetDateRefresh.request(context, force = true)
    }
}

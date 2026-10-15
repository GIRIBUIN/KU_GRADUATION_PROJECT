package com.example.ku_task_management

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.dexterous.flutterlocalnotifications.WidgetNotificationBridge
import es.antonborri.home_widget.HomeWidgetPlugin

/** Native widget reminders work while the Flutter engine/main screen is closed. */
object WidgetReminders {
    private const val OWNED = "workspace_native_reminders"
    private const val CHANNEL = "task_due"

    fun notificationId(id: String): Int {
        var hash = 0
        for (character in id) hash = (hash * 31 + character.code) and 0x7fffffff
        return if (hash == 0) 1 else hash
    }

    private fun pending(context: Context, id: String, at: Long = 0): PendingIntent {
        val intent = Intent(context, WidgetReminderReceiver::class.java).apply {
            data = Uri.Builder().scheme("kutodo-reminder").authority("task").appendPath(id).build()
            putExtra("task_id", id); putExtra("scheduled_at", at)
        }
        return PendingIntent.getBroadcast(context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    @Synchronized fun cancel(context: Context, id: String) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(pending(context, id))
        val prefs = HomeWidgetPlugin.getData(context)
        val owned = prefs.getStringSet(OWNED, emptySet())!!.toMutableSet()
        owned.remove(id)
        prefs.edit().putStringSet(OWNED, owned).commit()
    }

    @Synchronized fun reconcile(context: Context, id: String) {
        val store = WidgetTaskStore(context)
        // Read successfully before replacing an alarm; a busy DB must not erase its retry ownership.
        val task = store.tasks().firstOrNull { it.id == id }
        val offset = if (task?.status == "active") store.reminder(id) else null
        cancel(context, id)
        WidgetNotificationBridge.cancel(context, notificationId(id))
        if (task == null || offset == null) return
        val due = task.due ?: return
        val at = due - offset * 60L
        if (task.status != "active" || at <= System.currentTimeMillis() / 1000L) return
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = pending(context, id, at)
        try {
            if (Build.VERSION.SDK_INT < 31 || alarm.canScheduleExactAlarms())
                alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at * 1000, intent)
            else alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at * 1000, intent)
        } catch (_: SecurityException) {
            // Exact-alarm permission can be revoked between checking and scheduling.
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at * 1000, intent)
        }
        val prefs = HomeWidgetPlugin.getData(context)
        val owned = prefs.getStringSet(OWNED, emptySet())!!.toMutableSet()
        owned.add(id)
        prefs.edit().putStringSet(OWNED, owned).commit()
    }

    @Synchronized fun restore(context: Context) {
        val ids = HomeWidgetPlugin.getData(context).getStringSet(OWNED, emptySet())!!.toSet()
        ids.forEach { id -> runCatching { reconcile(context, id) } }
    }

    @Synchronized fun show(context: Context, id: String, expectedAt: Long) {
        val store = WidgetTaskStore(context)
        val task = store.task(id)
        val offset = store.reminder(id) ?: return
        if (task.status != "active" || task.due == null || task.due - offset * 60L != expectedAt) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(NotificationChannel(CHANNEL, "작업 마감 알림", NotificationManager.IMPORTANCE_HIGH))
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val open = WidgetWorkspaceActivity.pending(context, "edit", id)
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.widget_notification_icon).setContentTitle("KU Todo")
            .setContentText("${task.title} 마감 알림").setContentIntent(open).setAutoCancel(true).build()
        NotificationManagerCompat.from(context).notify(notificationId(id), notification)
    }
}

class WidgetReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        runCatching {
            WidgetReminders.show(context, intent.getStringExtra("task_id") ?: return,
                intent.getLongExtra("scheduled_at", 0))
        }
    }
}

class WidgetWorkspaceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action in setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED,
                Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) {
            val result = goAsync()
            Thread {
                try { WidgetReminders.restore(context); WidgetWorkspaceRenderer.refreshAll(context) }
                finally { result.finish() }
            }.start()
        }
    }
}

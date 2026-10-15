package com.dexterous.flutterlocalnotifications;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import androidx.core.app.NotificationManagerCompat;

/** Cancel the plugin's alarm AND reboot cache when a widget changes a task.
 * Kept in this package to use the plugin's package-visible cache API, without reflection.
 * Compatibility is verified against the pinned flutter_local_notifications 21.x dependency.
 */
public final class WidgetNotificationBridge {
  private WidgetNotificationBridge() {}

  public static void cancel(Context context, int id) {
    Intent intent = new Intent(context, ScheduledNotificationReceiver.class);
    PendingIntent pending = PendingIntent.getBroadcast(context, id, intent,
        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    ((AlarmManager) context.getSystemService(Context.ALARM_SERVICE)).cancel(pending);
    NotificationManagerCompat.from(context).cancel(id);
    FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, id);
  }
}

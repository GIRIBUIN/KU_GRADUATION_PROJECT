package com.example.ku_task_management

import android.app.Activity
import android.os.Bundle
import androidx.core.app.NotificationManagerCompat

class WidgetTaskCompleteActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val taskId = intent.getStringExtra(WidgetActions.EXTRA_TASK_ID)
        if (!taskId.isNullOrBlank()) {
            WidgetTaskCompleter.completeTask(applicationContext, taskId)
            NotificationManagerCompat.from(this).cancel(notificationIdForTask(taskId))
        }

        finish()
    }

    private fun notificationIdForTask(taskId: String): Int {
        var hash = 0
        for (character in taskId) {
            hash = (hash * 31 + character.code) and 0x7fffffff
        }
        return if (hash == 0) 1 else hash
    }
}

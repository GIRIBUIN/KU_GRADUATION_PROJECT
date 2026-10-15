package com.example.ku_task_management

import android.app.Activity
import android.os.Bundle
import android.widget.Toast

/** 위젯 RemoteViews 클릭을 받는 투명 트램폴린 Activity */
class WidgetTaskCompleteActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val taskId = intent.getStringExtra(WidgetActions.EXTRA_TASK_ID)
        val widgetKind = intent.getStringExtra(WidgetActions.EXTRA_WIDGET_KIND)
            ?: WidgetActions.WIDGET_KIND_TODAY
        if (!taskId.isNullOrBlank()) {
            runCatching { WidgetTaskCompleter.completeTask(
                context = applicationContext,
                taskId = taskId,
                widgetKind = widgetKind,
            ) }.onFailure { Toast.makeText(this, it.message ?: "일정을 변경하지 못했습니다.", Toast.LENGTH_LONG).show() }
        }

        finish()
    }

}

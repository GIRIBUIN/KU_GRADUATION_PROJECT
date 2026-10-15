package com.example.ku_task_management

import java.time.Instant
import java.time.ZoneId

/** Shared by the compact widget and its expanded workspace. No Android dependencies. */
data class WidgetTask(
    val id: String,
    val title: String,
    val origin: String,
    val status: String,
    val due: Long?,
    val priority: String?,
    val memo: String,
    val course: String,
    val syncedAt: Long?,
    val order: Int,
    val tags: Set<String> = emptySet(),
    val folders: Set<String> = emptySet(),
    val subDone: Int = 0,
    val subTotal: Int = 0,
) {
    val completed get() = status == "completed"
    val academic get() = origin == "ecampus"
}

data class WidgetOptions(
    val period: String = "today",
    val origin: String = "all",
    val tag: String = "",
    val folder: String = "",
    val sort: String = "due",
    val showCompleted: Boolean = false,
    val dark: Boolean = false,
    val largeText: Boolean = false,
    val opacity: Int = 100,
    val page: Int = 0,
)

object WidgetTaskPolicy {
    fun reminderMinutes(value: Int, notifyTime: String?): Int =
        if (notifyTime != null && Regex("^\\d{2}:\\d{2}$").matches(notifyTime.trim()) && value in 0..7)
            value * 24 * 60 else value

    fun select(
        tasks: List<WidgetTask>, options: WidgetOptions, now: Long,
        pins: Set<String> = emptySet(), urgentDays: Int = 3,
        zone: ZoneId = ZoneId.systemDefault(),
    ): List<WidgetTask> {
        val today = Instant.ofEpochSecond(now).atZone(zone).toLocalDate()
        val monday = today.minusDays((today.dayOfWeek.value - 1).toLong())
        return tasks.filter { task ->
            val visible = when (options.period) {
                "trash" -> task.status == "deleted" || task.status == "excluded"
                else -> task.status == "active" || (options.showCompleted && task.completed)
            }
            val date = task.due?.let { Instant.ofEpochSecond(it).atZone(zone).toLocalDate() }
            visible && (options.origin == "all" || task.origin == options.origin) &&
                (options.tag.isEmpty() || options.tag in task.tags) &&
                (options.folder.isEmpty() || options.folder in task.folders) && when (options.period) {
                    "today" -> date == today // Keep today's overdue items visible.
                    "week" -> date != null && !date.isBefore(monday) && date.isBefore(monday.plusDays(7))
                    "urgent" -> task.due != null && task.due >= now && date != null &&
                        !date.isAfter(today.plusDays(urgentDays.toLong()))
                    "overdue" -> task.due != null && task.due < now && !task.completed
                    "pinned" -> task.id in pins
                    else -> true
                }
        }.sortedWith(compareBy<WidgetTask> { it.completed }
            .thenBy { if (it.id in pins) 0 else 1 }
            .thenBy { if (options.sort == "priority") rank(it.priority) else 0 }
            .thenBy { if (options.sort == "order") it.order.toLong() else it.due ?: Long.MAX_VALUE }
            .thenBy { it.order }.thenBy { it.id })
    }

    private fun rank(priority: String?) = when (priority) { "high" -> 0; "medium" -> 1; "low" -> 2; else -> 3 }

    fun postponedDue(task: WidgetTask, days: Long): Long {
        require(!task.academic) { "학업 일정의 원본 마감은 변경할 수 없습니다. 알림 시각을 조정하세요." }
        require(days > 0) { "미루는 날짜를 확인해주세요." }
        val due = requireNotNull(task.due) { "먼저 마감일을 지정해주세요." }
        return Instant.ofEpochSecond(due).atZone(ZoneId.systemDefault()).plusDays(days).toEpochSecond()
    }
}

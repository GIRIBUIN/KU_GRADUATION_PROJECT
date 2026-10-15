package com.example.ku_task_management

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID

/** Uses the existing Drift schema; never creates a second database or changes its schema. */
class WidgetTaskStore(private val context: Context) {
    private val prefs get() = HomeWidgetPlugin.getData(context)
    private fun now() = System.currentTimeMillis() / 1000L

    private fun databaseFile(): File {
        val configured = prefs.getString("widget_db_path", null)?.let(::File)
        val candidates = listOfNotNull(configured,
            File(context.applicationInfo.dataDir, "app_flutter/ku_task_management.sqlite"),
            File(context.filesDir, "ku_task_management.sqlite"))
        return candidates.firstOrNull { it.isFile }
            ?: error("앱에서 최초 설정을 마친 후 위젯을 사용해주세요.")
    }

    private fun <T> read(block: (SQLiteDatabase) -> T): T =
        SQLiteDatabase.openDatabase(databaseFile().absolutePath, null, SQLiteDatabase.OPEN_READWRITE).use { db ->
            db.rawQuery("PRAGMA busy_timeout = 3000", null).use { it.moveToFirst() }
            block(db)
        }

    private fun <T> mutate(block: (SQLiteDatabase) -> T): T {
        val result = read { db ->
            db.beginTransaction()
            try { block(db).also { db.setTransactionSuccessful() } }
            finally { db.endTransaction() }
        }
        prefs.edit().putBoolean("widget_refresh_required", true).commit()
        return result
    }

    fun tasks(): List<WidgetTask> = read { db ->
        val tags = relations(db, "task_tags", "tag_id")
        val folders = relations(db, "task_folders", "folder_id")
        db.rawQuery("""
            SELECT t.*, (SELECT COUNT(*) FROM sub_tasks s WHERE s.task_id=t.id) sub_total,
              (SELECT COUNT(*) FROM sub_tasks s WHERE s.task_id=t.id AND s.is_done=1) sub_done
            FROM tasks t
        """.trimIndent(), null).use { c ->
            buildList {
                while (c.moveToNext()) {
                    val id = c.string("id")
                    add(WidgetTask(id, c.string("title"), c.string("origin"), c.string("status"),
                        c.longOrNull("due_date"), c.string("priority").ifEmpty { null }, c.string("memo"),
                        c.string("ecampus_source_course"), c.longOrNull("ecampus_last_synced_at"),
                        c.getInt(c.getColumnIndexOrThrow("sort_order")), tags[id] ?: emptySet(),
                        folders[id] ?: emptySet(), c.getInt(c.getColumnIndexOrThrow("sub_done")),
                        c.getInt(c.getColumnIndexOrThrow("sub_total"))))
                }
            }
        }
    }

    fun task(id: String) = tasks().firstOrNull { it.id == id } ?: error("일정을 찾을 수 없습니다.")

    private fun relations(db: SQLiteDatabase, table: String, column: String): Map<String, Set<String>> =
        db.rawQuery("SELECT task_id, $column FROM $table", null).use { c ->
            val result = mutableMapOf<String, MutableSet<String>>()
            while (c.moveToNext()) result.getOrPut(c.getString(0)) { mutableSetOf() }.add(c.getString(1))
            result
        }

    fun metadata(table: String): List<Pair<String, String>> {
        require(table in setOf("tags", "folders"))
        return read { db -> db.rawQuery("SELECT id, name FROM $table ORDER BY name", null).use { c ->
            buildList { while (c.moveToNext()) add(c.getString(0) to c.getString(1)) }
        } }
    }

    fun createMetadata(table: String, name: String): String {
        require(table in setOf("tags", "folders"))
        require(name.trim().isNotEmpty() && name.length <= 100) { "이름은 1~100자로 입력해주세요." }
        return mutate { db ->
            db.rawQuery("SELECT id FROM $table WHERE name=?", arrayOf(name.trim())).use { c ->
                if (c.moveToFirst()) c.getString(0) else {
                    val id = "widget_${UUID.randomUUID()}"
                    db.insertOrThrow(table, null, ContentValues().apply {
                        put("id", id); put("name", name.trim()); put("color", "#1262D6")
                        put("created_at", now()); put("updated_at", now())
                    })
                    id
                }
            }
        }
    }

    fun appSetting(key: String, default: String): String = read { db ->
        db.rawQuery("SELECT value FROM app_settings WHERE key=?", arrayOf(key)).use {
            if (it.moveToFirst()) it.getString(0) else default
        }
    }

    fun options(widgetId: Int, kind: String): WidgetOptions {
        val raw = prefs.getString("workspace_options_$widgetId", null)
        val json = try { JSONObject(raw ?: "{}") } catch (_: Exception) { JSONObject() }
        return WidgetOptions(json.optString("period", when (kind) { "weekly" -> "week"; "calendar" -> "all"; else -> "today" }),
            json.optString("origin", "all"), json.optString("tag"), json.optString("folder"),
            json.optString("sort", "due"), json.optBoolean("showCompleted", kind != "today"),
            json.optBoolean("dark"), json.optBoolean("largeText"), json.optInt("opacity", 100),
            json.optInt("page", 0))
    }

    fun saveOptions(widgetId: Int, options: WidgetOptions) {
        prefs.edit().putString("workspace_options_$widgetId", JSONObject().apply {
            put("period", options.period); put("origin", options.origin); put("tag", options.tag)
            put("folder", options.folder); put("sort", options.sort); put("showCompleted", options.showCompleted)
            put("dark", options.dark); put("largeText", options.largeText); put("opacity", options.opacity)
            put("page", options.page)
        }.toString()).commit()
    }

    fun pins(): Set<String> = prefs.getStringSet("workspace_pins", emptySet())!!.toSet()
    fun pin(id: String, pinned: Boolean) {
        val values = pins().toMutableSet()
        if (pinned) values.add(id) else values.remove(id)
        prefs.edit().putStringSet("workspace_pins", values).commit()
    }

    fun saveTask(id: String?, title: String, due: Long?, priority: String?, memo: String,
                 tags: Set<String>, folder: String?, reminderMinutes: Int?): String {
        require(title.trim().isNotEmpty()) { "제목을 입력해주세요." }
        require(title.length <= 500) { "제목은 500자 이내로 입력해주세요." }
        require(priority == null || priority in setOf("high", "medium", "low")) { "우선순위를 확인해주세요." }
        val taskId = id ?: "widget_${UUID.randomUUID()}"
        mutate { db ->
            val existing = id?.let { findRow(db, it) }
            if (id != null) require(existing != null) { "삭제된 일정입니다. 다시 확인해주세요." }
            require(existing?.optString("status") !in listOf("deleted", "excluded")) { "먼저 일정을 복구해주세요." }
            if (existing?.optString("origin") == "ecampus") {
                val oldDue = if (existing.isNull("due_date")) null else existing.getLong("due_date")
                require(due == oldDue) { "학업 일정의 원본 마감은 변경할 수 없습니다." }
            }
            val values = ContentValues().apply {
                put("title", title.trim()); put("memo", memo); put("updated_at", now())
                if (due == null) putNull("due_date") else put("due_date", due)
                if (priority == null) putNull("priority") else put("priority", priority)
            }
            if (existing == null) {
                values.put("id", taskId); values.put("origin", "personal"); values.put("status", "active")
                values.put("created_at", now())
                db.rawQuery("SELECT COALESCE(MAX(sort_order),-1)+1 FROM tasks", null).use {
                    it.moveToFirst(); values.put("sort_order", it.getInt(0))
                }
                db.insertOrThrow("tasks", null, values)
            } else check(db.update("tasks", values, "id=?", arrayOf(taskId)) == 1)
            db.delete("task_tags", "task_id=?", arrayOf(taskId))
            tags.forEach { tag ->
                db.execSQL("INSERT INTO task_tags(task_id,tag_id) SELECT ?,id FROM tags WHERE id=?", arrayOf(taskId, tag))
            }
            db.delete("task_folders", "task_id=?", arrayOf(taskId))
            if (!folder.isNullOrEmpty()) db.execSQL(
                "INSERT INTO task_folders(task_id,folder_id) SELECT ?,id FROM folders WHERE id=?", arrayOf(taskId, folder))
            saveReminder(db, taskId, reminderMinutes)
        }
        WidgetReminders.reconcile(context, taskId)
        return taskId
    }

    fun changeStatus(id: String, status: String, remember: Boolean = true) {
        require(status in setOf("active", "completed", "deleted", "excluded"))
        var undo: JSONObject? = null
        mutate { db ->
            val old = findRow(db, id) ?: error("일정을 찾을 수 없습니다.")
            require(status != "excluded" || old.optString("origin") == "ecampus")
            require(status != "excluded" || old.getString("status") == "active") {
                "진행 중인 학업 일정만 제외할 수 있습니다. 완료 기록은 유지해주세요."
            }
            undo = JSONObject().put("id", id).put("status", old.getString("status"))
                .put("completed_at", old.opt("completed_at")).put("deleted_at", old.opt("deleted_at"))
                .put("expected_status", status)
            val values = ContentValues().apply {
                put("status", status); put("updated_at", now())
                if (status == "completed") put("completed_at", now()) else putNull("completed_at")
                if (status == "deleted" || status == "excluded") put("deleted_at", now()) else putNull("deleted_at")
            }
            check(db.update("tasks", values, "id=?", arrayOf(id)) == 1)
        }
        if (remember) prefs.edit().putString("workspace_undo", undo.toString()).commit()
        // Ignore legacy pending changes for a task that has now been written synchronously.
        clearLegacyPending(id)
        WidgetReminders.reconcile(context, id)
    }

    fun undo(): Boolean {
        val raw = prefs.getString("workspace_undo", null) ?: return false
        val data = JSONObject(raw)
        val id = data.getString("id")
        mutate { db ->
            val current = findRow(db, id) ?: error("일정을 찾을 수 없습니다.")
            require(current.getString("status") == data.getString("expected_status")) {
                "이후 변경된 일정입니다. 삭제 목록에서 상태를 확인해주세요."
            }
            val values = ContentValues().apply {
                put("status", data.getString("status")); put("updated_at", now())
                for (key in listOf("completed_at", "deleted_at")) {
                    if (data.isNull(key)) putNull(key) else put(key, data.getLong(key))
                }
            }
            db.update("tasks", values, "id=?", arrayOf(id))
        }
        prefs.edit().remove("workspace_undo").commit()
        WidgetReminders.reconcile(context, id)
        return true
    }

    fun postpone(id: String, days: Long) {
        val due = WidgetTaskPolicy.postponedDue(task(id), days)
        mutate { db -> db.execSQL("UPDATE tasks SET due_date=?,updated_at=? WHERE id=? AND origin='personal' AND status='active'",
            arrayOf<Any>(due, now(), id)) }
        WidgetReminders.reconcile(context, id)
    }

    fun reminder(id: String): Int? = read { db ->
        db.rawQuery("SELECT enabled,days_before_due,notify_time FROM notification_settings WHERE task_id=?", arrayOf(id)).use { c ->
            if (!c.moveToFirst() || c.getInt(0) == 0) null else {
                val amount = c.getInt(1)
                WidgetTaskPolicy.reminderMinutes(amount, c.getString(2))
            }
        }
    }

    fun setReminder(id: String, minutes: Int?) {
        mutate { db -> saveReminder(db, id, minutes) }
        WidgetReminders.reconcile(context, id)
    }

    private fun saveReminder(db: SQLiteDatabase, id: String, minutes: Int?) {
        require(minutes == null || minutes >= 0)
        // task_id is not a UNIQUE column, so update an existing row instead of INSERT OR REPLACE.
        val values = ContentValues().apply {
            put("enabled", if (minutes == null) 0 else 1); put("days_before_due", minutes ?: 60)
            put("notify_time", "relative"); putNull("scheduled_at")
        }
        if (db.update("notification_settings", values, "task_id=?", arrayOf(id)) == 0) {
            values.put("id", "notification_$id"); values.put("task_id", id)
            db.insertOrThrow("notification_settings", null, values)
        }
    }

    fun subTasks(id: String): List<Triple<String, String, Boolean>> = read { db ->
        db.rawQuery("SELECT id,title,is_done FROM sub_tasks WHERE task_id=? ORDER BY created_at,id", arrayOf(id)).use { c ->
            buildList { while (c.moveToNext()) add(Triple(c.getString(0), c.getString(1), c.getInt(2) != 0)) }
        }
    }

    fun saveSubTask(taskId: String, id: String?, title: String, done: Boolean) {
        require(title.trim().isNotEmpty()) { "하위 작업 제목을 입력해주세요." }
        mutate { db ->
            val parent = findRow(db, taskId) ?: error("일정을 찾을 수 없습니다.")
            require(parent.getString("status") in setOf("active", "completed")) { "먼저 일정을 복구해주세요." }
            val values = ContentValues().apply {
                put("title", title.trim()); put("is_done", if (done) 1 else 0); put("updated_at", now())
            }
            if (id == null) {
                values.put("id", "widget_sub_${UUID.randomUUID()}"); values.put("task_id", taskId); values.put("created_at", now())
                db.insertOrThrow("sub_tasks", null, values)
            } else db.update("sub_tasks", values, "id=? AND task_id=?", arrayOf(id, taskId))
        }
    }

    fun deleteSubTask(taskId: String, id: String) = mutate { db ->
        db.delete("sub_tasks", "id=? AND task_id=?", arrayOf(id, taskId))
    }

    private fun findRow(db: SQLiteDatabase, id: String): JSONObject? =
        db.rawQuery("SELECT * FROM tasks WHERE id=?", arrayOf(id)).use { c ->
            if (!c.moveToFirst()) null else JSONObject().apply {
                c.columnNames.forEachIndexed { i, name -> put(name, if (c.isNull(i)) JSONObject.NULL else c.getString(i)) }
            }
        }

    private fun clearLegacyPending(id: String) {
        val editor = prefs.edit()
        for (key in listOf("widget_pending_completions", "widget_pending_uncompletions")) {
            val items = try { JSONArray(prefs.getString(key, "[]")) } catch (_: Exception) { JSONArray() }
            val next = JSONArray()
            for (i in 0 until items.length()) if (items.optString(i) != id) next.put(items.optString(i))
            editor.putString(key, next.toString())
        }
        editor.commit()
    }

    private fun Cursor.string(name: String): String = getColumnIndexOrThrow(name).let { if (isNull(it)) "" else getString(it) }
    private fun Cursor.longOrNull(name: String): Long? = getColumnIndexOrThrow(name).let { if (isNull(it)) null else getLong(it) }
}

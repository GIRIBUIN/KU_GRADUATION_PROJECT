package com.example.ku_task_management

import android.app.Application
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import es.antonborri.home_widget.HomeWidgetPlugin
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.annotation.SQLiteMode
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
@SQLiteMode(SQLiteMode.Mode.NATIVE)
class WidgetTaskStoreTest {
    private lateinit var context: Application
    private lateinit var file: File
    private lateinit var store: WidgetTaskStore

    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        file = context.getDatabasePath("widget-test.sqlite")
        file.parentFile!!.mkdirs()
        val schema = javaClass.classLoader!!.getResourceAsStream("widget_schema.sql")!!.bufferedReader().readText()
        SQLiteDatabase.openOrCreateDatabase(file, null).use { db ->
            schema.split(';').filter { it.isNotBlank() }.forEach { db.execSQL(it) }
            db.execSQL("INSERT INTO app_settings(key,value,updated_at) VALUES('defaultNotificationEnabled','false',0)")
            db.execSQL("INSERT INTO tags(id,name,color,created_at,updated_at) VALUES('course','자료구조','#1262D6',0,0)")
            db.execSQL("INSERT INTO folders(id,name,created_at,updated_at) VALUES('school','학업',0,0)")
            db.version = 5
        }
        HomeWidgetPlugin.getData(context).edit().clear().putString("widget_db_path", file.absolutePath).commit()
        store = WidgetTaskStore(context)
    }

    @After fun teardown() { context.deleteDatabase("widget-test.sqlite") }

    private fun create(title: String = "시험 준비", due: Long? = System.currentTimeMillis() / 1000 + 86400) =
        store.saveTask(null, title, due, "high", "메모", setOf("course"), "school", null)

    @Test fun createEditAndRelationsPersistWithoutFlutter() {
        val id = create()
        val created = store.task(id)
        assertEquals("personal", created.origin)
        assertEquals(setOf("course"), created.tags)
        assertEquals(setOf("school"), created.folders)
        store.saveTask(id, "수정한 제목", created.due, null, "변경한 메모", emptySet(), null, null)
        val updated = store.task(id)
        assertEquals("수정한 제목", updated.title)
        assertTrue(updated.tags.isEmpty()); assertTrue(updated.folders.isEmpty())
        assertEquals(5, SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY).use { it.version })
    }

    @Test fun completeUndoDeleteRestoreUseSameDatabaseImmediately() {
        val id = create()
        store.changeStatus(id, "completed")
        assertEquals("completed", store.task(id).status)
        assertTrue(store.undo()); assertEquals("active", store.task(id).status)
        store.changeStatus(id, "deleted")
        assertEquals("deleted", store.task(id).status)
        store.changeStatus(id, "active")
        assertEquals("active", store.task(id).status)
    }

    @Test fun undoDoesNotOverwriteAnotherStatusChange() {
        val id = create()
        store.changeStatus(id, "completed")
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use {
            it.execSQL("UPDATE tasks SET status='deleted' WHERE id=?", arrayOf(id))
        }
        try { store.undo(); fail("Must not overwrite a newer edit") } catch (_: IllegalArgumentException) {}
        assertEquals("deleted", store.task(id).status)
    }

    @Test fun academicDeadlineAndSourceIdentityAreProtected() {
        val id = create()
        val due = store.task(id).due
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use {
            it.execSQL("UPDATE tasks SET origin='ecampus',ecampus_source_key='source-123',ecampus_source_due_date=due_date WHERE id=?", arrayOf(id))
        }
        try { store.saveTask(id, "변경", due!! + 86400, null, "", emptySet(), null, null); fail("Must protect the source deadline") }
        catch (_: IllegalArgumentException) {}
        assertEquals(due, store.task(id).due)
        store.changeStatus(id, "excluded")
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY).use { db ->
            db.rawQuery("SELECT ecampus_source_key FROM tasks WHERE id=?", arrayOf(id)).use { c ->
                c.moveToFirst(); assertEquals("source-123", c.getString(0))
            }
        }
        store.changeStatus(id, "active"); assertEquals("active", store.task(id).status)
    }

    @Test fun subTasksAndProgressPersist() {
        val id = create()
        store.saveSubTask(id, null, "자료 조사", false)
        val sub = store.subTasks(id).single()
        store.saveSubTask(id, sub.first, "자료 조사 완료", true)
        assertEquals(1, store.task(id).subDone); assertEquals(1, store.task(id).subTotal)
        store.deleteSubTask(id, sub.first)
        assertEquals(0, store.task(id).subTotal)
    }

    @Test fun optionsArePerWidgetWhilePinsAreShared() {
        store.saveOptions(11, WidgetOptions(period = "overdue", origin = "ecampus", dark = true))
        store.saveOptions(22, WidgetOptions(period = "all", tag = "course"))
        assertEquals("overdue", store.options(11, "today").period)
        assertEquals("all", store.options(22, "today").period)
        store.pin("task", true); assertEquals(setOf("task"), store.pins())
        store.pin("task", false); assertTrue(store.pins().isEmpty())
    }

    @Test fun savesReminderAndCancelsOnCompletion() {
        val id = create()
        store.setReminder(id, 60); assertEquals(60, store.reminder(id))
        val alarm = shadowOf(context.getSystemService(android.content.Context.ALARM_SERVICE) as android.app.AlarmManager)
        assertFalse(alarm.scheduledAlarms.isEmpty())
        store.changeStatus(id, "completed")
        assertTrue(alarm.scheduledAlarms.isEmpty())
        store.changeStatus(id, "active")
        assertFalse(alarm.scheduledAlarms.isEmpty())
    }

    @Test fun appSourceRefreshReschedulesWidgetOwnedReminder() {
        val due = System.currentTimeMillis() / 1000 + 86400
        val id = create(due = due)
        store.setReminder(id, 60)
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use {
            it.execSQL("UPDATE tasks SET origin='ecampus',due_date=? WHERE id=?", arrayOf<Any>(due + 7200, id))
        }
        WidgetReminders.restore(context)
        val alarm = shadowOf(context.getSystemService(android.content.Context.ALARM_SERVICE) as android.app.AlarmManager)
        assertEquals((due + 7200 - 3600) * 1000, alarm.scheduledAlarms.single().triggerAtTime)
    }

    @Test fun compactCompletionUsesBroadcastAndNeverOpensAnActivity() {
        val id = create()
        val callback = WidgetWorkspaceActivity.pending(context, "toggle", id, 1, "today")
        assertTrue(callback.isBroadcast)
        callback.send()
        for (attempt in 0 until 1000) {
            shadowOf(Looper.getMainLooper()).idle()
            if (store.task(id).completed) break
            Thread.sleep(10)
        }
        assertTrue(store.task(id).completed)
        assertNull(shadowOf(context).nextStartedActivity)
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun expandedAddSavesWithoutStartingMainActivity() {
        val intent = Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "add")
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java, intent).setup()
        val activity = controller.get()
        val views = descendants(activity.findViewById(android.R.id.content))
        views.filterIsInstance<EditText>().first { it.hint == "제목" }.setText("위젯에서 생성")
        preview(activity.findViewById(android.R.id.content), "expanded-add", 480, 840)
        views.filterIsInstance<Button>().first { it.text == "저장" }.performClick()
        for (attempt in 0 until 1000) {
            shadowOf(Looper.getMainLooper()).idle()
            if (activity.isFinishing) break
            Thread.sleep(10)
        }
        assertEquals("위젯에서 생성", store.tasks().single().title)
        assertTrue(activity.isFinishing)
        assertNull(shadowOf(activity).nextStartedActivity)
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun remoteViewsRenderResizeAndOpenWidgetEditor() {
        val today = java.time.LocalDate.now().atTime(23, 59).atZone(java.time.ZoneId.systemDefault()).toEpochSecond()
        repeat(9) { create("자료구조 과제 ${it + 1}", today) }
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        val shadow = shadowOf(manager)
        val id = shadow.createWidget(ScheduleWidgetProvider::class.java, R.layout.widget_workspace)
        val small = shadow.getViewFor(id)
        val smallCount = small.findViewById<android.widget.LinearLayout>(R.id.workspace_rows).childCount
        assertTrue(smallCount > 0)
        preview(small, "today-widget", 440, 300)
        manager.updateAppWidgetOptions(id, android.os.Bundle().apply {
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 480)
        })
        val large = shadow.getViewFor(id)
        assertTrue(large.findViewById<android.widget.LinearLayout>(R.id.workspace_rows).childCount > smallCount)
        preview(large, "large-widget", 440, 480)
        large.findViewById<View>(R.id.workspace_row_body).performClick()
        val launched = shadowOf(context).nextStartedActivity
        assertEquals(WidgetWorkspaceActivity::class.java.name, launched.component!!.className)
        assertEquals("edit", launched.getStringExtra("action"))
    }

    private fun preview(view: View, name: String, width: Int, height: Int) {
        view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, width, height)
        val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
        view.draw(android.graphics.Canvas(bitmap))
        val directory = File(System.getProperty("widget.preview.dir") ?: "../../build/widget-previews")
        directory.mkdirs()
        File(directory, "$name.png").outputStream().use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
    }

    private fun descendants(root: View): List<View> = listOf(root) + if (root is ViewGroup)
        (0 until root.childCount).flatMap { descendants(root.getChildAt(it)) } else emptyList()
}

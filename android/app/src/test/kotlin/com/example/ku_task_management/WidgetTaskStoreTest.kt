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
        preview(activity.findViewById(android.R.id.content), "expanded-add", 480, 540)
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
    fun compactListHasNoManagementButtonsAndExpandsWithoutChangingTasks() {
        val today = java.time.LocalDate.now().atTime(23, 59).atZone(java.time.ZoneId.systemDefault()).toEpochSecond()
        val titles = listOf("자료구조 과제 정리", "팀 프로젝트 회의 준비", "운영체제 복습", "발표 자료 검토",
            "시험 범위 정리", "회의 내용 기록", "논문 읽기", "실습 보고서", "다음 주 계획")
        titles.forEach { create(it, today) }
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        val shadow = shadowOf(manager)
        val id = shadow.createWidget(ScheduleWidgetProvider::class.java, R.layout.widget_workspace)
        val small = shadow.getViewFor(id)
        val smallCount = small.findViewById<android.widget.LinearLayout>(R.id.workspace_rows).childCount
        assertTrue(smallCount > 0)
        val compactLabels = descendants(small).filterIsInstance<android.widget.TextView>().map { it.text.toString() }
        assertFalse(compactLabels.any { it in setOf("+ 추가", "설정", "확대 보기", "되돌리기", "‹", "›", "↻") })
        assertEquals("+${9 - smallCount}개 일정", small.findViewById<android.widget.TextView>(R.id.workspace_more).text.toString())
        assertFalse(small.findViewById<View>(R.id.workspace_row_check).hasOnClickListeners())
        preview(small, "today-widget", 440, 300)
        manager.updateAppWidgetOptions(id, android.os.Bundle().apply {
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 480)
        })
        val large = shadow.getViewFor(id)
        assertTrue(large.findViewById<android.widget.LinearLayout>(R.id.workspace_rows).childCount > smallCount)
        preview(large, "large-widget", 440, 480)
        val weeklyId = shadow.createWidget(WeeklyScheduleWidgetProvider::class.java, R.layout.widget_workspace)
        preview(shadow.getViewFor(weeklyId), "weekly-widget", 440, 300)
        large.findViewById<View>(R.id.workspace_row_body).performClick()
        val launched = shadowOf(context).nextStartedActivity
        assertEquals(WidgetWorkspaceActivity::class.java.name, launched.component!!.className)
        assertEquals("list", launched.getStringExtra("action"))
        assertTrue(store.tasks().none { it.completed })
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun calendarGridShowsDatesAndScheduleDotsAndOpensTheChosenDay() {
        val date = java.time.LocalDate.now().withDayOfMonth(15)
        val due = date.atTime(18, 0).atZone(java.time.ZoneId.systemDefault()).toEpochSecond()
        create("달력에서 확인할 일정", due)
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        val shadow = shadowOf(manager)
        val id = shadow.createWidget(CalendarWidgetProvider::class.java, R.layout.widget_calendar)
        val widget = shadow.getViewFor(id)
        val weeks = widget.findViewById<android.widget.LinearLayout>(R.id.calendar_weeks)
        assertEquals(6, weeks.childCount)
        val cells = (0 until 6).flatMap { week ->
            val row = weeks.getChildAt(week) as android.widget.LinearLayout
            assertEquals(7, row.childCount)
            (0 until 7).map { row.getChildAt(it) }
        }
        assertEquals(42, cells.size)
        assertEquals(1, cells.count { it.findViewById<View>(R.id.calendar_day_dot).visibility == View.VISIBLE })
        val chosen = cells.single { it.contentDescription.toString().startsWith("${date.monthValue}월 15일,") }
        assertTrue(chosen.contentDescription.toString().contains("일정 1개"))
        preview(widget, "calendar-widget", 440, 360)
        chosen.performClick()
        val launched = shadowOf(context).nextStartedActivity
        assertEquals(WidgetWorkspaceActivity::class.java.name, launched.component!!.className)
        assertEquals("calendar", launched.getStringExtra("action"))
        assertEquals(date.toString(), launched.getStringExtra("selected_date"))
        val first = java.time.LocalDate.now().withDayOfMonth(1)
        val firstGridDay = first.minusDays((first.dayOfWeek.value % 7).toLong())
        // Each day has its own PendingIntent identity; the last cell cannot overwrite the first.
        cells.first().performClick()
        assertEquals(firstGridDay.toString(), shadowOf(context).nextStartedActivity.getStringExtra("selected_date"))
        manager.updateAppWidgetOptions(id, android.os.Bundle().apply {
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 400)
        })
        preview(shadow.getViewFor(id), "calendar-widget-large", 440, 400)
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun calendarPopupAddsToSelectedDayWithoutOpeningMainActivity() {
        val selected = java.time.LocalDate.now().plusMonths(1).withDayOfMonth(9)
        val intent = Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "calendar")
            .putExtra("kind", "calendar").putExtra("selected_date", selected.toString())
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java, intent).setup()
        val activity = controller.get()
        fun content() = descendants(activity.findViewById(android.R.id.content))
        assertEquals(selected, java.time.Instant.ofEpochMilli(content().filterIsInstance<android.widget.CalendarView>().single().date)
            .atZone(java.time.ZoneId.systemDefault()).toLocalDate())
        preview(activity.findViewById(android.R.id.content), "expanded-calendar", 480, 840)
        content().filterIsInstance<Button>().single { it.text == "+ 추가" }.performClick()
        content().filterIsInstance<EditText>().single { it.hint == "제목" }.setText("선택 날짜 일정")
        content().filterIsInstance<Button>().single { it.text == "저장" }.performClick()
        awaitCondition { activity.isFinishing }
        val saved = store.tasks().single()
        assertEquals(selected, java.time.Instant.ofEpochSecond(saved.due!!).atZone(java.time.ZoneId.systemDefault()).toLocalDate())
        assertNull(shadowOf(activity).nextStartedActivity)
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun calendarDotsFollowFiltersAndRefreshAfterCompletionInPopup() {
        val selected = java.time.LocalDate.now()
        val id = create(due = selected.atTime(20, 0).atZone(java.time.ZoneId.systemDefault()).toEpochSecond())
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        val shadow = shadowOf(manager)
        val widgetId = shadow.createWidget(CalendarWidgetProvider::class.java, R.layout.widget_calendar)
        store.saveOptions(widgetId, WidgetOptions(period = "all", showCompleted = false, dark = true, tag = "course"))
        WidgetWorkspaceRenderer.refreshAll(context)
        fun dots() = descendants(shadow.getViewFor(widgetId)).count { it.id == R.id.calendar_day_dot && it.visibility == View.VISIBLE }
        assertEquals(1, dots())
        preview(shadow.getViewFor(widgetId), "calendar-widget-dark", 440, 360)
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "calendar")
                .putExtra("kind", "calendar").putExtra("widget_id", widgetId).putExtra("selected_date", selected.toString())).setup()
        val activity = controller.get()
        descendants(activity.findViewById(android.R.id.content)).filterIsInstance<android.widget.CheckBox>().single().performClick()
        awaitCondition { store.task(id).completed && dots() == 0 }
        assertNull(shadowOf(activity).nextStartedActivity)
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun expandedListCanCompleteAndOpenExistingManagementMenu() {
        val due = java.time.LocalDate.now().atTime(23, 59).atZone(java.time.ZoneId.systemDefault()).toEpochSecond()
        val id = create("팝업에서 완료할 일정", due)
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "list")).setup()
        val activity = controller.get()
        fun content() = descendants(activity.findViewById(android.R.id.content))
        preview(activity.findViewById(android.R.id.content), "expanded-list", 480, 360)
        content().filterIsInstance<android.widget.CheckBox>().single().performClick()
        awaitCondition { store.task(id).completed && content().filterIsInstance<android.widget.CheckBox>().isEmpty() }
        content().filterIsInstance<Button>().single { it.text == "더 보기" }.performClick()
        val dialog = org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog()
        val items = shadowOf(dialog).items.map { it.toString() }
        assertTrue(items.containsAll(listOf("필터·설정", "삭제·제외된 일정", "중요도·긴급도", "집중 타이머", "새로고침")))
        dialog.dismiss()
        assertNull(shadowOf(activity).nextStartedActivity)
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun outsideTapClosesPopupButConfirmsUnsavedDraft() {
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "add")).setup()
        val activity = controller.get()
        descendants(activity.findViewById(android.R.id.content)).filterIsInstance<EditText>()
            .single { it.hint == "제목" }.setText("작성 중인 일정")
        val event = android.view.MotionEvent.obtain(0, 0, android.view.MotionEvent.ACTION_OUTSIDE, -100f, -100f, 0)
        activity.onTouchEvent(event)
        assertFalse(activity.isFinishing)
        val dialog = org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog()
        assertEquals("작성 중인 내용을 버릴까요?", shadowOf(dialog).title.toString())
        dialog.getButton(android.app.AlertDialog.BUTTON_POSITIVE).performClick()
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(activity.isFinishing)
        assertTrue(store.tasks().isEmpty())
        event.recycle()
        controller.pause().stop().destroy()

        val cleanController = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java)).setup()
        val cleanEvent = android.view.MotionEvent.obtain(0, 0, android.view.MotionEvent.ACTION_OUTSIDE, -100f, -100f, 0)
        cleanController.get().onTouchEvent(cleanEvent)
        assertTrue(cleanController.get().isFinishing)
        cleanEvent.recycle()
        cleanController.pause().stop().destroy()
    }

    private fun awaitCondition(condition: () -> Boolean) {
        for (attempt in 0 until 1000) {
            shadowOf(Looper.getMainLooper()).idle()
            if (condition()) return
            Thread.sleep(10)
        }
        assertTrue("Widget work did not complete", condition())
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun editorShowsOnlyEverydayFieldsAndRetainsOptionsWhenFolded() {
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "add")).setup()
        val activity = controller.get()
        fun controls() = descendants(activity.findViewById(android.R.id.content))
        fun button(text: String) = controls().filterIsInstance<Button>().single { it.text.toString() == text }
        val visible = controls().filterIsInstance<Button>().filter { it.isShown }.map { it.text.toString() }
        assertEquals(5, visible.size)
        assertTrue(visible.containsAll(listOf("닫기", "태그 선택 (0)", "더 보기 ▾", "저장")))
        assertTrue(visible.any { it.startsWith("기한:") })
        controls().filterIsInstance<EditText>().single { it.hint == "제목" }.setText("간단히 추가")
        controls().filterIsInstance<EditText>().single { it.hint == "메모" }.setText("유지할 메모")
        assertFalse(button("우선순위: 없음").isShown)
        button("더 보기 ▾").performClick()
        assertTrue(button("우선순위: 없음").isShown)
        button("우선순위: 없음").performClick()
        org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog().let { dialog ->
            dialog.listView.performItemClick(null, 1, 1)
        }
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(button("우선순위: 높음").isShown)
        preview(activity.findViewById(android.R.id.content), "expanded-add-more", 480, 780)
        button("접기 ▴").performClick()
        assertFalse(button("우선순위: 높음").isShown)
        button("저장").performClick()
        awaitCondition { activity.isFinishing }
        val task = store.tasks().single()
        assertEquals("간단히 추가", task.title)
        assertEquals("유지할 메모", task.memo)
        assertEquals("high", task.priority)
        assertNull(shadowOf(activity).nextStartedActivity)
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun noDeadlineCanBeChosenWithoutOpeningMoreOrDisablingAnInvisibleReminder() {
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use {
            it.execSQL("UPDATE app_settings SET value='true' WHERE key='defaultNotificationEnabled'")
        }
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "add")).setup()
        val activity = controller.get()
        val controls = descendants(activity.findViewById(android.R.id.content))
        controls.filterIsInstance<EditText>().single { it.hint == "제목" }.setText("기한 없는 할 일")
        controls.filterIsInstance<Button>().single { it.text.startsWith("기한:") }.performClick()
        org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog()
            .getButton(android.app.AlertDialog.BUTTON_NEUTRAL).performClick()
        shadowOf(Looper.getMainLooper()).idle()
        controls.filterIsInstance<Button>().single { it.text == "저장" }.performClick()
        awaitCondition { activity.isFinishing }
        val task = store.tasks().single()
        assertNull(task.due)
        assertNull(store.reminder(task.id))
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun listAdaptsFromSmallTileToWideCardWithoutClippingRows() {
        val due = java.time.LocalDate.now().atTime(23, 59).atZone(java.time.ZoneId.systemDefault()).toEpochSecond()
        repeat(15) { create("크기별 일정 ${it + 1}", due) }
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        val shadow = shadowOf(manager)
        val id = shadow.createWidget(ScheduleWidgetProvider::class.java, R.layout.widget_workspace)
        val counts = mutableListOf<Int>()
        for ((width, height) in listOf(140 to 72, 220 to 180, 360 to 480)) {
            manager.updateAppWidgetOptions(id, android.os.Bundle().apply {
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
            })
            val widget = shadow.getViewFor(id)
            preview(widget, "list-${width}x$height", width, height)
            val rows = widget.findViewById<android.widget.LinearLayout>(R.id.workspace_rows)
            counts.add(rows.childCount)
            assertTrue(rows.childCount > 0)
            assertTrue("Row clipped at ${width}x$height", rows.getChildAt(rows.childCount - 1).bottom <= rows.height)
            widget.findViewById<View>(R.id.workspace_surface).performClick()
            assertEquals("list", shadowOf(context).nextStartedActivity.getStringExtra("action"))
        }
        assertTrue(counts[0] < counts[1]); assertTrue(counts[1] < counts[2])
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun smallCalendarStillShowsAllSixWeeksAndFortyTwoDates() {
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        val shadow = shadowOf(manager)
        val id = shadow.createWidget(CalendarWidgetProvider::class.java, R.layout.widget_calendar)
        manager.updateAppWidgetOptions(id, android.os.Bundle().apply {
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 240)
        })
        val widget = shadow.getViewFor(id)
        preview(widget, "calendar-small", 180, 240)
        val weeks = widget.findViewById<android.widget.LinearLayout>(R.id.calendar_weeks)
        assertEquals(6, weeks.childCount)
        assertEquals(42, descendants(weeks).count { it.id == R.id.calendar_day_cell })
        assertTrue(weeks.getChildAt(5).bottom <= weeks.height)
        for (cell in descendants(weeks).filter { it.id == R.id.calendar_day_cell }) {
            val number = cell.findViewById<View>(R.id.calendar_day_number)
            val dot = cell.findViewById<View>(R.id.calendar_day_dot)
            assertTrue(number.top >= 0)
            assertTrue(dot.bottom <= cell.height)
        }
    }

    private fun preview(view: View, name: String, width: Int, height: Int) {
        // Settle card bounds after the host's size/visible-area listener requests its next layout pass.
        repeat(3) {
            view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
                View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
            view.layout(0, 0, width, height)
        }
        val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
        view.draw(android.graphics.Canvas(bitmap))
        val directory = File(System.getProperty("widget.preview.dir") ?: "../../build/widget-previews")
        directory.mkdirs()
        File(directory, "$name.png").outputStream().use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    @Config(qualifiers = "w360dp-h800dp-mdpi")
    fun popupCardsLeaveClickableBackdropForCalendarAndEveryAddEntry() {
        create("위젯에서 확인할 일정", java.time.LocalDate.now().atTime(23, 59).atZone(java.time.ZoneId.systemDefault()).toEpochSecond())
        for ((kind, action) in listOf("today" to "list", "weekly" to "list", "calendar" to "calendar",
                "today" to "add", "weekly" to "add")) {
            val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
                Intent(context, WidgetWorkspaceActivity::class.java).putExtra("kind", kind).putExtra("action", action)).setup()
            val activity = controller.get()
            val content = activity.findViewById<ViewGroup>(android.R.id.content)
            val host = content.findViewWithTag<android.widget.FrameLayout>("widget_popup_backdrop")
            preview(host, "popup-$kind-$action", 360, 800)
            val card = content.findViewWithTag<View>("widget_popup_card")
            // Insets or decor must never consume the space reserved for dismissal.
            assertTrue(card.left >= 24)
            assertTrue(360 - card.right >= 24)
            assertTrue(card.top > 0)
            assertTrue(card.bottom < 800)
            assertTrue(card.height <= 800 * .68f)
            tap(host, card.left + 2f, card.top + 2f)
            assertFalse("Card padding should consume the tap", activity.isFinishing)
            tap(host, 4f, 400f)
            assertTrue("Backdrop must close $kind/$action", activity.isFinishing)
            assertNull(shadowOf(activity).nextStartedActivity)
            controller.pause().stop().destroy()
        }
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    @Config(qualifiers = "w360dp-h800dp-mdpi")
    fun expandedEditorKeepsBackdropAndSaveButtonWhenVisibleAreaShrinks() {
        val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
            Intent(context, WidgetWorkspaceActivity::class.java).putExtra("action", "add")).setup()
        val activity = controller.get()
        val content = activity.findViewById<ViewGroup>(android.R.id.content)
        val host = content.findViewWithTag<android.widget.FrameLayout>("widget_popup_backdrop")
        descendants(content).filterIsInstance<Button>().single { it.text == "더 보기 ▾" }.performClick()
        descendants(content).filterIsInstance<EditText>().single { it.hint == "제목" }.requestFocus()
        preview(host, "popup-add-reduced-viewport", 360, 350)
        val card = content.findViewWithTag<View>("widget_popup_card")
        assertTrue(card.top > 0)
        assertTrue("Card bounds ${card.left},${card.top},${card.right},${card.bottom} exceed reduced viewport", card.bottom < 350)
        assertTrue(card.height <= 350 * .68f)
        val save = descendants(card).filterIsInstance<Button>().single { it.text == "저장" }
        assertTrue(save.isShown)
        assertTrue(save.bottom <= card.height - card.paddingBottom)
        for (input in descendants(card).filterIsInstance<EditText>()) {
            assertTrue(input.imeOptions and android.view.inputmethod.EditorInfo.IME_FLAG_NO_FULLSCREEN != 0)
        }
        tap(host, 4f, 170f)
        assertTrue(activity.isFinishing)
        controller.pause().stop().destroy()
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun todayAndWeeklyHaveNoCalendarEntryIncludingOlderIntents() {
        for (kind in listOf("today", "weekly")) for (action in listOf("list", "calendar")) {
            val controller = Robolectric.buildActivity(WidgetWorkspaceActivity::class.java,
                Intent(context, WidgetWorkspaceActivity::class.java).putExtra("kind", kind).putExtra("action", action)).setup()
            val activity = controller.get()
            val views = descendants(activity.findViewById(android.R.id.content))
            assertFalse(views.filterIsInstance<Button>().any { it.text == "캘린더" })
            assertTrue(views.none { it is android.widget.CalendarView })
            assertTrue(views.filterIsInstance<Button>().any { it.text == "+ 추가" })
            controller.pause().stop().destroy()
        }
    }

    private fun tap(view: View, x: Float, y: Float) {
        val time = android.os.SystemClock.uptimeMillis()
        val down = android.view.MotionEvent.obtain(time, time, android.view.MotionEvent.ACTION_DOWN, x, y, 0)
        val up = android.view.MotionEvent.obtain(time, time + 30, android.view.MotionEvent.ACTION_UP, x, y, 0)
        view.dispatchTouchEvent(down); view.dispatchTouchEvent(up)
        shadowOf(Looper.getMainLooper()).idle()
        down.recycle(); up.recycle()
    }

    private fun descendants(root: View): List<View> = listOf(root) + if (root is ViewGroup)
        (0 until root.childCount).flatMap { descendants(root.getChildAt(it)) } else emptyList()
}

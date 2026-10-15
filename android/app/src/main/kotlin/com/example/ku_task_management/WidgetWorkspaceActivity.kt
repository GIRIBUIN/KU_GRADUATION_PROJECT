package com.example.ku_task_management

import android.Manifest
import android.app.Activity
import android.app.ActivityOptions
import android.app.AlertDialog
import android.app.DatePickerDialog
import android.app.PendingIntent
import android.app.TimePickerDialog
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognizerIntent
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.*
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.util.Locale
import java.util.concurrent.Executors

/** A floating widget workspace. Never launches MainActivity or the Flutter engine. */
class WidgetWorkspaceActivity : Activity() {
    private lateinit var store: WidgetTaskStore
    private lateinit var body: LinearLayout
    private lateinit var rootPanel: LinearLayout
    private var widgetId = 0
    private var kind = "today"
    private var screen = "list"
    private var selectedDate = LocalDate.now()
    private var listCount = 5
    private var busy = false
    private var voiceTarget: EditText? = null
    private var currentTaskId: String? = null
    private var pendingSave: (() -> Unit)? = null
    private var draft: (() -> Bundle)? = null
    private var initialDraft: Bundle? = null
    private var focusTick: Runnable? = null
    private val handler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var alive = true
    private val ink = Color.rgb(17, 24, 39)
    private val blue = Color.rgb(18, 98, 214)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        store = WidgetTaskStore(this)
        widgetId = intent.getIntExtra("widget_id", 0)
        kind = intent.getStringExtra("kind") ?: "today"
        selectedDate = runCatching { LocalDate.parse(savedInstanceState?.getString("selected_date")
            ?: intent.getStringExtra("selected_date")) }.getOrDefault(LocalDate.now())
        window.addFlags(WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH)
        if (Build.VERSION.SDK_INT >= 33) onBackInvokedDispatcher.registerOnBackInvokedCallback(
            android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT) { closeWorkspace() }
        sizeWindow()
        val action = savedInstanceState?.getString("screen") ?: intent.getStringExtra("action") ?: "list"
        val id = savedInstanceState?.getString("task_id") ?: intent.getStringExtra("task_id")
        when (action) {
            "toggle" -> work(close = true) {
                val task = store.task(requireNotNull(id))
                if (task.status in setOf("deleted", "excluded")) error("삭제 목록에서 먼저 복구해주세요.")
                store.changeStatus(task.id, if (task.completed) "active" else "completed")
            }
            "undo" -> work(close = true) { if (!store.undo()) error("되돌릴 변경 사항이 없습니다.") }
            "refresh" -> work(close = true) { store.tasks() }
            "previous", "next" -> work(close = true) {
                val options = store.options(widgetId, kind)
                store.saveOptions(widgetId, options.copy(page = (options.page + if (action == "next") 1 else -1).coerceAtLeast(0)))
            }
            "settings" -> safely { settings() }
            "calendar" -> safely { calendar() }
            "add", "edit" -> safely {
                editor(id, savedInstanceState?.getBundle("draft"))
                initialDraft = savedInstanceState?.getBundle("initial_draft") ?: initialDraft
            }
            else -> safely { list() }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString("screen", if (draft != null) "edit" else if (screen == "calendar") "calendar" else "list")
        outState.putString("selected_date", selectedDate.toString())
        outState.putString("task_id", currentTaskId)
        draft?.let { outState.putBundle("draft", it()) }
        initialDraft?.let { outState.putBundle("initial_draft", it) }
    }

    override fun onDestroy() {
        alive = false; handler.removeCallbacksAndMessages(null); worker.shutdown()
        super.onDestroy()
    }

    override fun onPause() {
        focusTick?.let { handler.removeCallbacks(it) }
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        focusTick?.let { handler.removeCallbacks(it); handler.post(it) }
    }

    override fun onConfigurationChanged(config: android.content.res.Configuration) {
        super.onConfigurationChanged(config); sizeWindow()
    }

    private fun sizeWindow() {
        val fraction = if (screen == "edit") .88 else if (screen == "calendar") .84 else .76
        val maximum = (resources.displayMetrics.heightPixels * fraction).toInt()
            .coerceAtMost(dp(if (screen == "edit") 780 else 720))
        val height = if (screen == "list") dp(280 + listCount.coerceAtMost(8) * 60).coerceAtMost(maximum) else maximum
        window.setLayout((resources.displayMetrics.widthPixels * .94).toInt().coerceAtMost(dp(580)),
            height)
        window.setGravity(Gravity.CENTER)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
    }

    private fun panel(title: String): LinearLayout {
        focusTick?.let { handler.removeCallbacks(it) }
        focusTick = null
        draft = null
        initialDraft = null
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; setPadding(dp(18), dp(12), dp(18), dp(12))
            background = shape(Color.WHITE)
        }
        rootPanel = root
        val header = row()
        header.addView(label(title, 19, true), LinearLayout.LayoutParams(0, dp(44), 1f))
        header.addView(button("닫기") { closeWorkspace() }, LinearLayout.LayoutParams(dp(64), dp(44)))
        root.addView(header)
        val scroll = ScrollView(this).apply { isFillViewport = false }
        body = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        scroll.addView(body)
        root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1f))
        setContentView(root); sizeWindow()
        return body
    }

    private fun safely(action: () -> Unit) {
        try { action() } catch (error: Exception) {
            panel("일정 위젯"); body.addView(label(error.message ?: "일정을 불러오지 못했습니다."))
            body.addView(button("다시 불러오기") { safely { list() } })
        }
    }

    private fun work(close: Boolean = false, after: (() -> Unit)? = null, action: () -> Unit) {
        if (busy) return
        busy = true
        worker.execute {
            val error = runCatching { action() }.exceptionOrNull()
            // Always rebuild from persisted data, including a partial notification scheduling failure.
            runCatching { WidgetWorkspaceRenderer.refreshAll(applicationContext) }
            handler.post {
                busy = false
                if (!alive) return@post
                if (error != null) {
                    Toast.makeText(this, error.message ?: "작업을 처리하지 못했습니다.", Toast.LENGTH_LONG).show()
                    if (close) finish()
                } else if (close) finish() else after?.invoke()
            }
        }
    }

    private fun list() {
        screen = "list"
        val options = store.options(widgetId, kind)
        panel(WidgetWorkspaceRenderer.periodLabel(options.period))
        val toolbar = row()
        toolbar.addView(button("+ 추가", primary = true) { safely { editor(null) } }, weight())
        toolbar.addView(button("캘린더") { safely { calendar() } }, weight())
        toolbar.addView(button("더 보기") { moreMenu() }, weight())
        body.addView(toolbar)
        val search = input("일정 검색")
        body.addView(search)
        val rows = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        body.addView(rows)
        val allTasks = store.tasks()
        val tasks = WidgetTaskPolicy.select(allTasks, options, System.currentTimeMillis() / 1000, store.pins(),
            store.appSetting("urgentDueDays", "3").toIntOrNull() ?: 3)
        val progress = WidgetTaskPolicy.select(allTasks, options.copy(showCompleted = true),
            System.currentTimeMillis() / 1000, store.pins(), store.appSetting("urgentDueDays", "3").toIntOrNull() ?: 3)
        body.addView(label("${WidgetWorkspaceRenderer.originLabel(options.origin)} · ${tasks.size}개 일정" +
            if (options.period == "trash") "" else " · ${progress.count { it.completed }}/${progress.size} 완료", 12), 1)
        fun populate(query: String) {
            rows.removeAllViews()
            val matches = tasks.filter { it.title.contains(query, true) || it.course.contains(query, true) || it.memo.contains(query, true) }
            if (matches.isEmpty()) rows.addView(label("표시할 일정이 없습니다. + 추가 또는 필터를 사용하세요.", 13))
            for (task in matches) {
                val line = row()
                val check = CheckBox(this).apply {
                    isChecked = task.completed; contentDescription = "${task.title} 완료 상태"
                    isEnabled = task.status in setOf("active", "completed")
                    setOnClickListener { work(after = { list() }) { store.changeStatus(task.id, if (task.completed) "active" else "completed") } }
                }
                line.addView(check, LinearLayout.LayoutParams(dp(48), dp(56)))
                val text = label((if (task.id in store.pins()) "★ " else "") + task.title + "\n" +
                    WidgetWorkspaceRenderer.dueLabel(task.due), 14)
                text.setOnClickListener { safely { editor(task.id) } }
                line.addView(text, LinearLayout.LayoutParams(0, -2, 1f))
                rows.addView(line)
            }
        }
        populate("")
        search.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { populate(s.toString()) }
            override fun afterTextChanged(s: Editable?) {}
        })
        val latest = allTasks.mapNotNull { it.syncedAt }.maxOrNull()
        if (latest != null) body.addView(label("학업 일정 최근 반영: " + Instant.ofEpochSecond(latest).atZone(ZoneId.systemDefault())
            .format(java.time.format.DateTimeFormatter.ofPattern("M/d HH:mm")), 11))
        listCount = tasks.size
        sizeWindow()
    }

    private fun moreMenu() {
        choose("일정 관리", listOf("필터·설정", "전체 일정", "중요 일정", "삭제·제외된 일정", "중요도·긴급도",
            "집중 타이머", "마지막 변경 되돌리기", "새로고침")) { index -> safely {
            when (index) {
                0 -> settings()
                1 -> changePeriod("all")
                2 -> changePeriod("pinned")
                3 -> changePeriod("trash")
                4 -> matrix()
                5 -> focus()
                6 -> work(after = { home() }) { if (!store.undo()) error("되돌릴 변경 사항이 없습니다.") }
                7 -> work(after = { home() }) { store.tasks() }
            }
        } }
    }

    private fun home() { if (kind == "calendar") calendar() else list() }

    private fun changePeriod(period: String) {
        store.saveOptions(widgetId, store.options(widgetId, kind).copy(period = period, page = 0))
        WidgetWorkspaceRenderer.refreshAll(this); safely { list() }
    }

    private fun calendar() {
        screen = "calendar"
        panel("캘린더")
        val options = store.options(widgetId, kind).copy(period = "all")
        val tasks = WidgetTaskPolicy.select(store.tasks(), options, System.currentTimeMillis() / 1000, store.pins())
        val calendar = CalendarView(this)
        calendar.date = selectedDate.atTime(12, 0).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val toolbar = row()
        toolbar.addView(button("+ 추가", primary = true) {
            editor(null, Bundle().apply { putLong("due", selectedDate.atTime(23, 59).atZone(ZoneId.systemDefault()).toEpochSecond()) })
        }, weight())
        toolbar.addView(button("목록") { list() }, weight())
        toolbar.addView(button("더 보기") { moreMenu() }, weight())
        body.addView(toolbar)
        body.addView(calendar, LinearLayout.LayoutParams(-1, dp(320)))
        val dayLabel = label("", 15, true)
        body.addView(dayLabel)
        val rows = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        body.addView(rows)
        fun update() {
            dayLabel.text = "${selectedDate.monthValue}월 ${selectedDate.dayOfMonth}일"
            rows.removeAllViews()
            val matches = tasks.filter { it.due?.let { due ->
                Instant.ofEpochSecond(due).atZone(ZoneId.systemDefault()).toLocalDate() == selectedDate
            } == true }
            if (matches.isEmpty()) rows.addView(label("이 날짜에 등록된 일정이 없습니다.", 13))
            for (task in matches) {
                val line = row()
                line.addView(CheckBox(this).apply {
                    isChecked = task.completed; contentDescription = "${task.title} 완료 상태"
                    setOnClickListener { work(after = { calendar() }) { store.changeStatus(task.id, if (task.completed) "active" else "completed") } }
                }, LinearLayout.LayoutParams(dp(48), dp(56)))
                line.addView(label(task.title + "\n" + WidgetWorkspaceRenderer.dueLabel(task.due), 14).apply {
                    setOnClickListener { safely { editor(task.id) } }
                }, LinearLayout.LayoutParams(0, -2, 1f))
                rows.addView(line)
            }
        }
        calendar.setOnDateChangeListener { _, year, month, day -> selectedDate = LocalDate.of(year, month + 1, day); update() }
        update()
        body.addView(button("목록으로") { list() })
    }

    private fun matrix() {
        panel("중요도·긴급도")
        val now = System.currentTimeMillis() / 1000
        val days = store.appSetting("urgentDueDays", "3").toLongOrNull() ?: 3
        val urgentEnd = LocalDate.now().plusDays(days).atTime(23, 59).atZone(ZoneId.systemDefault()).toEpochSecond()
        val tasks = WidgetTaskPolicy.select(store.tasks(), store.options(widgetId, kind).copy(period = "all", showCompleted = false), now, store.pins())
        body.addView(label("중요: 높은 우선순위 또는 고정한 일정\n긴급: 기한 초과 또는 ${days}일 이내 마감", 12))
        for ((important, urgent) in listOf(true to true, true to false, false to true, false to false)) {
            val matches = tasks.filter { task ->
                (task.priority == "high" || task.id in store.pins()) == important &&
                    (task.due != null && task.due <= urgentEnd) == urgent
            }
            body.addView(label("${if (important) "중요" else "중요도 낮음"} · ${if (urgent) "긴급" else "여유"} (${matches.size})", 15, true))
            if (matches.isEmpty()) body.addView(label("등록된 일정이 없습니다.", 12))
            matches.forEach { task -> body.addView(button(task.title) { safely { editor(task.id) } }) }
        }
        body.addView(button("목록으로") { list() })
    }

    private fun editor(id: String?, restored: Bundle? = null) {
        screen = "edit"
        currentTaskId = id
        val task = id?.let { store.task(it) }
        if (task != null && task.status in setOf("deleted", "excluded")) {
            panel("일정 복구")
            body.addView(label(task.title, 18, true))
            body.addView(label("복구하면 기존 목록에 다시 표시됩니다. 학업 원본 정보는 유지됩니다.", 13))
            body.addView(button("복구") { work(after = { list() }) { store.changeStatus(task.id, "active") } })
            return
        }
        panel(if (id == null) "새 일정" else "일정 수정")
        if (id == null) body.addView(label("개인 일정으로 저장됩니다.", 12))
        val title = input("제목", restored?.getString("title") ?: task?.title ?: "")
        title.setSingleLine(false); title.maxLines = 3
        body.addView(title)
        var due: Long? = if (restored != null) {
            if (restored.containsKey("due")) restored.getLong("due") else null
        } else task?.due ?: if (id == null) LocalDate.now().atTime(23, 59).atZone(ZoneId.systemDefault()).toEpochSecond() else null
        var priority = if (restored != null) restored.getString("priority") else task?.priority
        var reminder = if (restored?.containsKey("reminder") == true) restored.getInt("reminder").takeIf { it >= 0 }
            else if (id != null) store.reminder(id) else if (store.appSetting("defaultNotificationEnabled", "true") == "true") {
                WidgetTaskPolicy.reminderMinutes(store.appSetting("defaultNotificationDays", "60").toIntOrNull() ?: 60,
                    store.appSetting("defaultNotificationTime", "relative"))
            } else null
        val widgetOptions = store.options(widgetId, kind)
        val selectedTags = (restored?.getStringArrayList("tags")?.toSet() ?: task?.tags
            ?: widgetOptions.tag.takeIf { it.isNotEmpty() }?.let { setOf(it) } ?: emptySet()).toMutableSet()
        var folder = if (restored?.containsKey("folder") == true) restored.getString("folder")
            else task?.folders?.firstOrNull() ?: if (id == null) widgetOptions.folder.takeIf { it.isNotEmpty() } else null
        val dueButton = button(WidgetWorkspaceRenderer.dueLabel(due)) {}
        dueButton.setOnClickListener {
            if (task?.academic == true) toast("학업 마감은 원본을 유지합니다. 알림 시각을 변경할 수 있습니다.")
            else pickDate(due) { due = it; dueButton.text = WidgetWorkspaceRenderer.dueLabel(due) }
        }
        body.addView(dueButton)
        if (task?.academic != true) body.addView(button("마감 없음") { due = null; dueButton.text = "마감 없음" })
        if (task?.academic == true) body.addView(label("${task.course}\n학업 마감은 원본을 유지합니다.", 12))
        val priorityButton = button("우선순위: ${priorityLabel(priority)}") {}
        priorityButton.setOnClickListener {
            choose("우선순위", listOf("없음", "높음", "보통", "낮음")) { index ->
                priority = listOf(null, "high", "medium", "low")[index]
                priorityButton.text = "우선순위: ${priorityLabel(priority)}"
            }
        }
        body.addView(priorityButton)
        val memo = input("메모", restored?.getString("memo") ?: task?.memo ?: "").apply { minLines = 2; maxLines = 5 }
        body.addView(memo)
        val tagButton = button("태그 선택 (${selectedTags.size})") {}
        tagButton.setOnClickListener {
            val tags = store.metadata("tags")
            val chosen = selectedTags.toMutableSet()
            AlertDialog.Builder(this).setTitle("태그")
                .setMultiChoiceItems(tags.map { it.second }.toTypedArray(), BooleanArray(tags.size) { tags[it].first in selectedTags }) { _, which, checked ->
                    if (checked) chosen.add(tags[which].first) else chosen.remove(tags[which].first)
                }.setNegativeButton("취소", null).setPositiveButton("확인") { _, _ ->
                    selectedTags.clear(); selectedTags.addAll(chosen)
                    tagButton.text = "태그 선택 (${selectedTags.size})"
                }.show()
        }
        body.addView(tagButton)
        var folders = store.metadata("folders")
        val folderButton = button("폴더: ${folders.firstOrNull { it.first == folder }?.second ?: "없음"}") {}
        folderButton.setOnClickListener {
            choose("폴더", listOf("없음") + folders.map { it.second }) { index ->
                folder = if (index == 0) null else folders[index - 1].first
                folderButton.text = "폴더: ${folders.firstOrNull { it.first == folder }?.second ?: "없음"}"
            }
        }
        body.addView(folderButton)
        val metadataActions = row()
        metadataActions.addView(button("+ 태그") { textDialog("새 태그", "") { name ->
            work(after = { tagButton.text = "태그 선택 (${selectedTags.size})" }) {
                selectedTags.add(store.createMetadata("tags", name))
            }
        } }, weight())
        metadataActions.addView(button("+ 폴더") { textDialog("새 폴더", "") { name ->
            work(after = {
                folders = store.metadata("folders")
                folderButton.text = "폴더: ${folders.firstOrNull { it.first == folder }?.second ?: "없음"}"
            }) { folder = store.createMetadata("folders", name) }
        } }, weight())
        body.addView(metadataActions)
        val reminderButton = button(reminderLabel(reminder)) {}
        reminderButton.setOnClickListener {
            choose("마감 알림", listOf("끄기", "마감 시각", "10분 전", "30분 전", "1시간 전", "1일 전")) { index ->
                reminder = listOf(null, 0, 10, 30, 60, 1440)[index]
                reminderButton.text = reminderLabel(reminder)
                if (reminder != null) requestNotificationPermission()
            }
        }
        body.addView(reminderButton)
        val helpers = row()
        helpers.addView(button("음성 입력") { voiceTarget = title; voice() }, weight())
        if (id == null) helpers.addView(button("템플릿") {
            choose("빠른 입력", listOf("과제 작업", "시험 공부", "팀 미팅", "개인 일정")) { i ->
                title.setText(listOf("과제 작업", "시험 공부", "팀 미팅", "개인 일정")[i])
                memo.setText(listOf("자료 확인 → 초안 → 검토", "범위 확인 → 개념 정리 → 문제 풀이", "안건과 준비물을 적어주세요.", "")[i])
            }
        }, weight())
        body.addView(helpers)
        if (id != null) {
            val pin = CheckBox(this).apply {
                text = "중요 일정으로 고정"; isChecked = id in store.pins(); setTextColor(ink)
                setOnCheckedChangeListener { _, checked -> store.pin(id, checked); WidgetWorkspaceRenderer.refreshAll(this@WidgetWorkspaceActivity) }
            }
            body.addView(pin)
            body.addView(button(if (task!!.completed) "미완료로 되돌리기" else "완료 처리") {
                work(after = { list() }) { store.changeStatus(id, if (task.completed) "active" else "completed") }
            })
            if (!task.academic && !task.completed) {
                val postpone = row()
                fun postponeDraft(days: Long) {
                    if (due == null) { toast("먼저 마감일을 지정해주세요."); return }
                    due = WidgetTaskPolicy.postponedDue(task.copy(due = due), days)
                    dueButton.text = WidgetWorkspaceRenderer.dueLabel(due)
                }
                postpone.addView(button("하루 미루기") { postponeDraft(1) }, weight())
                postpone.addView(button("일주일 미루기") { postponeDraft(7) }, weight())
                body.addView(postpone)
            }
            val snooze = button("알림만 1시간 후로") {
                work(after = { editor(id) }) {
                    val deadline = task.due ?: error("먼저 마감일을 지정해주세요.")
                    val offset = (deadline - System.currentTimeMillis() / 1000 - 3600) / 60
                    require(offset >= 0) { "마감까지 1시간 이상 남은 일정에서 사용할 수 있습니다." }
                    store.setReminder(id, offset.toInt())
                }
            }
            body.addView(snooze)
            body.addView(button("집중 타이머") {
                if (!hasDraftChanges()) focus(id) else AlertDialog.Builder(this)
                    .setTitle("수정 중인 내용을 버리고 이동할까요?")
                    .setNegativeButton("계속 작성", null)
                    .setPositiveButton("이동") { _, _ -> focus(id) }.show()
            })
            body.addView(button("개인 일정으로 복사") {
                val copyTitle = "${title.text} (사본)"
                val copyMemo = memo.text.toString()
                work(close = true) { store.saveTask(null, copyTitle, due, priority, copyMemo, selectedTags.toSet(), folder, reminder) }
            })
            subTasks(id)
            body.addView(button(if (task.academic) "목록에서 삭제" else "삭제") {
                AlertDialog.Builder(this).setTitle("일정을 삭제할까요?")
                    .setMessage("삭제·제외 목록에서 복구할 수 있습니다.")
                    .setNegativeButton("취소", null).setPositiveButton("삭제") { _, _ ->
                        work(after = { list() }) { store.changeStatus(id, "deleted") }
                    }.show()
            })
            if (task.academic && !task.completed) body.addView(button("동기화에서 제외") {
                AlertDialog.Builder(this).setTitle("이 학업 일정을 제외할까요?")
                    .setMessage("원본 키를 유지해 다음 동기화에서 신규로 가져오지 않습니다. 삭제·제외 목록에서 복구할 수 있습니다.")
                    .setNegativeButton("취소", null).setPositiveButton("제외") { _, _ ->
                        work(after = { list() }) { store.changeStatus(id, "excluded") }
                    }.show()
            })
        }
        draft = {
            Bundle().apply {
                putString("title", title.text.toString()); putString("memo", memo.text.toString())
                due?.let { putLong("due", it) }; putString("priority", priority)
                putInt("reminder", reminder ?: -1); putStringArrayList("tags", ArrayList(selectedTags)); putString("folder", folder)
            }
        }
        initialDraft = draft?.invoke()
        rootPanel.addView(button("저장", primary = true) {
            val savedTitle = title.text.toString(); val savedMemo = memo.text.toString()
            val savedDue = due; val savedPriority = priority; val savedTags = selectedTags.toSet()
            val savedFolder = folder; val savedReminder = reminder
            if (savedTitle.isBlank()) { title.error = "제목을 입력해주세요."; title.requestFocus(); return@button }
            if (reminder != null && due == null) { toast("마감 없는 일정은 알림을 끄거나 마감일을 지정해주세요."); return@button }
            val save = { work(close = true) { store.saveTask(id, savedTitle, savedDue, savedPriority, savedMemo, savedTags, savedFolder, savedReminder) } }
            if (reminder != null && Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                pendingSave = save
                requestNotificationPermission()
            } else save()
        })
    }

    private fun subTasks(taskId: String) {
        body.addView(label("하위 작업", 15, true))
        val container = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        body.addView(container)
        fun reload() {
            container.removeAllViews()
            for ((id, title, done) in store.subTasks(taskId)) {
                val line = row()
                val check = CheckBox(this).apply {
                    text = title; isChecked = done; setTextColor(ink)
                    setOnClickListener { work(after = { reload() }) { store.saveSubTask(taskId, id, title, !done) } }
                }
                line.addView(check, LinearLayout.LayoutParams(0, -2, 1f))
                line.addView(button("수정") { textDialog("하위 작업", title) { text ->
                    work(after = { reload() }) { store.saveSubTask(taskId, id, text, done) }
                } }, LinearLayout.LayoutParams(dp(60), dp(44)))
                line.addView(button("삭제") {
                    AlertDialog.Builder(this).setMessage("하위 작업을 삭제할까요?").setNegativeButton("취소", null)
                        .setPositiveButton("삭제") { _, _ -> work(after = { reload() }) { store.deleteSubTask(taskId, id) } }.show()
                }, LinearLayout.LayoutParams(dp(60), dp(44)))
                container.addView(line)
            }
        }
        reload()
        body.addView(button("+ 하위 작업") { textDialog("하위 작업 추가", "") { title ->
            work(after = { reload() }) { store.saveSubTask(taskId, null, title, false) }
        } })
    }

    private fun settings() {
        screen = "settings"
        panel("위젯 표시 설정")
        var options = store.options(widgetId, kind)
        fun selector(title: String, labels: List<String>, values: List<String>, current: () -> String, change: (String) -> Unit) {
            val control = button("$title: ${labels[values.indexOf(current()).coerceAtLeast(0)]}") {}
            control.setOnClickListener { choose(title, labels) { i -> change(values[i]); control.text = "$title: ${labels[i]}" } }
            body.addView(control)
        }
        if (kind != "calendar") selector("기간", listOf("오늘", "이번 주", "마감 임박", "기한 초과", "전체", "중요", "삭제·제외"),
            listOf("today", "week", "urgent", "overdue", "all", "pinned", "trash"), { options.period }) { options = options.copy(period = it) }
        selector("유형", listOf("전체", "학업", "개인"), listOf("all", "ecampus", "personal"), { options.origin }) { options = options.copy(origin = it) }
        val tags = store.metadata("tags")
        selector("태그", listOf("전체") + tags.map { it.second }, listOf("") + tags.map { it.first }, { options.tag }) { options = options.copy(tag = it) }
        val folders = store.metadata("folders")
        selector("폴더", listOf("전체") + folders.map { it.second }, listOf("") + folders.map { it.first }, { options.folder }) { options = options.copy(folder = it) }
        selector("정렬", listOf("마감일", "우선순위", "앱의 사용자 순서"), listOf("due", "priority", "order"), { options.sort }) { options = options.copy(sort = it) }
        fun check(title: String, selected: Boolean, change: (Boolean) -> Unit) {
            body.addView(CheckBox(this).apply { text = title; setTextColor(ink); isChecked = selected; setOnCheckedChangeListener { _, v -> change(v) } })
        }
        check("완료된 일정 표시", options.showCompleted) { options = options.copy(showCompleted = it) }
        check("어두운 배경", options.dark) { options = options.copy(dark = it) }
        check("큰 글자", options.largeText) { options = options.copy(largeText = it) }
        body.addView(label("배경 불투명도", 13))
        body.addView(SeekBar(this).apply {
            max = 80; progress = options.opacity - 20
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(bar: SeekBar?, progress: Int, fromUser: Boolean) { options = options.copy(opacity = progress + 20) }
                override fun onStartTrackingTouch(bar: SeekBar?) {}
                override fun onStopTrackingTouch(bar: SeekBar?) {}
            })
        })
        body.addView(label(if (kind == "calendar") "이 캘린더에만 적용됩니다. 날짜별 일정은 달력의 날짜를 눌러 확인하세요."
            else "이 위젯에만 적용됩니다. 홈 화면에서 위젯 크기를 늘리면 더 많은 일정이 표시됩니다.", 12))
        body.addView(button("설정 저장", primary = true) {
            store.saveOptions(widgetId, options.copy(page = 0)); WidgetWorkspaceRenderer.refreshAll(this); safely { home() }
        })
    }

    private fun focus(taskId: String? = null) {
        panel("집중 타이머")
        val prefs = HomeWidgetPlugin.getData(this)
        if (taskId != null) prefs.edit().putString("workspace_focus_task", taskId).apply()
        val taskTitle = runCatching { store.task(prefs.getString("workspace_focus_task", "")!!).title }.getOrNull()
        body.addView(label(taskTitle ?: "한 가지 일에 집중해보세요.", 15, true))
        val clock = label("25:00", 40, true).apply { gravity = Gravity.CENTER }
        body.addView(clock)
        fun remaining(): Long {
            val end = prefs.getLong("workspace_focus_end", 0)
            return if (end > 0) (end - System.currentTimeMillis()).coerceAtLeast(0) else prefs.getLong("workspace_focus_remaining", 25 * 60000L)
        }
        val ticker = object : Runnable {
            override fun run() {
                if (!alive || !clock.isAttachedToWindow) return
                val seconds = remaining() / 1000
                clock.text = if (seconds == 0L) "집중 완료" else String.format(Locale.KOREAN, "%02d:%02d", seconds / 60, seconds % 60)
                handler.postDelayed(this, 1000)
            }
        }
        focusTick = ticker
        handler.post(ticker)
        body.addView(button("시작·계속", primary = true) {
            val end = prefs.getLong("workspace_focus_end", 0)
            if (end > System.currentTimeMillis()) return@button
            prefs.edit().putLong("workspace_focus_end", System.currentTimeMillis() + (remaining().takeIf { it > 0 } ?: 25 * 60000L)).apply()
        })
        body.addView(button("일시 정지") { prefs.edit().putLong("workspace_focus_remaining", remaining()).putLong("workspace_focus_end", 0).apply() })
        body.addView(button("시간 선택·초기화") {
            choose("집중 시간", listOf("15분", "25분", "50분")) { i ->
                prefs.edit().putLong("workspace_focus_end", 0).putLong("workspace_focus_remaining", listOf(15, 25, 50)[i] * 60000L).apply()
            }
        })
        body.addView(label("패널을 닫아도 시간이 유지됩니다. 앱의 일정 마감·완료 상태는 변경하지 않습니다.", 12))
        body.addView(button("일정으로 돌아가기") { safely { list() } })
    }

    private fun pickDate(initial: Long?, selected: (Long) -> Unit) {
        val date = initial?.let { Instant.ofEpochSecond(it).atZone(ZoneId.systemDefault()) } ?: java.time.ZonedDateTime.now()
        DatePickerDialog(this, { _, year, month, day ->
            TimePickerDialog(this, { _, hour, minute -> selected(LocalDate.of(year, month + 1, day)
                .atTime(hour, minute).atZone(ZoneId.systemDefault()).toEpochSecond()) }, date.hour, date.minute, true).show()
        }, date.year, date.monthValue - 1, date.dayOfMonth).show()
    }
    private fun choose(title: String, values: List<String>, selected: (Int) -> Unit) {
        AlertDialog.Builder(this).setTitle(title).setItems(values.toTypedArray()) { _, which -> selected(which) }.setNegativeButton("취소", null).show()
    }
    private fun textDialog(title: String, value: String, save: (String) -> Unit) {
        val text = input(title, value)
        val dialog = AlertDialog.Builder(this).setTitle(title).setView(text).setNegativeButton("취소", null).setPositiveButton("저장", null).create()
        dialog.setOnShowListener { dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
            if (text.text.isBlank()) text.error = "제목을 입력해주세요." else { save(text.text.toString()); dialog.dismiss() }
        } }
        dialog.show()
    }
    private fun voice() {
        try { startActivityForResult(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR"); putExtra(RecognizerIntent.EXTRA_PROMPT, "할 일을 말해주세요.")
        }, 710) } catch (_: ActivityNotFoundException) { toast("음성 입력 앱이 없습니다. 키보드로 입력해주세요.") }
    }
    @Deprecated("Uses the platform Activity result callback without requiring another UI dependency")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 710 && resultCode == RESULT_OK) data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()?.let { voiceTarget?.setText(it) }
    }
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 711)
    }
    @Deprecated("Platform back callback for this lightweight native dialog")
    override fun onBackPressed() { closeWorkspace() }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val slop = ViewConfiguration.get(this).scaledWindowTouchSlop
        val decor = window.decorView
        val outside = event.action == MotionEvent.ACTION_OUTSIDE || (event.action == MotionEvent.ACTION_DOWN &&
            (event.x < -slop || event.y < -slop || event.x > decor.width + slop || event.y > decor.height + slop))
        if (outside) { closeWorkspace(); return true }
        return super.onTouchEvent(event)
    }

    private fun closeWorkspace() {
        if (busy) return
        if (!hasDraftChanges()) finish() else AlertDialog.Builder(this).setTitle("작성 중인 내용을 버릴까요?")
            .setMessage("저장 버튼을 누르면 위젯에 바로 반영됩니다.").setNegativeButton("계속 작성", null)
            .setPositiveButton("버리기") { _, _ -> finish() }.show()
    }

    private fun hasDraftChanges(): Boolean {
        val current = draft?.invoke()
        val original = initialDraft
        return current != null && original != null && (current.keySet() + original.keySet()).any { key ->
            @Suppress("DEPRECATION")
            current.get(key) != original.get(key)
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 711) {
            if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) toast("일정은 저장되지만 알림은 권한을 허용해야 표시됩니다.")
            val save = pendingSave; pendingSave = null; save?.invoke()
        }
    }
    private fun priorityLabel(value: String?) = when (value) { "high" -> "높음"; "medium" -> "보통"; "low" -> "낮음"; else -> "없음" }
    private fun reminderLabel(value: Int?) = if (value == null) "마감 알림: 꺼짐" else if (value == 0) "마감 알림: 마감 시각" else "마감 알림: ${value}분 전"
    private fun toast(message: String) = Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun weight() = LinearLayout.LayoutParams(0, dp(46), 1f)
    private fun row() = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
    private fun label(text: String, size: Int = 14, bold: Boolean = false) = TextView(this).apply {
        this.text = text; textSize = size.toFloat(); setTextColor(ink); setPadding(0, dp(8), 0, dp(8))
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }
    private fun input(hint: String, value: String = "") = EditText(this).apply {
        this.hint = hint; setText(value); textSize = 15f; setTextColor(ink); setHintTextColor(Color.GRAY)
        setPadding(dp(10), dp(8), dp(10), dp(8)); background = shape(Color.rgb(245, 247, 251))
        layoutParams = LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(8) }
    }
    private fun button(text: String, primary: Boolean = false, action: () -> Unit) = Button(this).apply {
        this.text = text; isAllCaps = false; textSize = 13f; minimumHeight = dp(44)
        setTextColor(if (primary) Color.WHITE else blue); background = shape(if (primary) blue else Color.rgb(239, 245, 255))
        layoutParams = LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(5); bottomMargin = dp(5) }
        setOnClickListener { if (!busy) action() }
    }
    private fun shape(color: Int) = GradientDrawable().apply { setColor(color); cornerRadius = dp(14).toFloat() }

    companion object {
        fun pending(context: android.content.Context, action: String, taskId: String? = null,
                    widgetId: Int = 0, kind: String = "today", selectedDate: String? = null): PendingIntent {
            val direct = action in setOf("toggle", "undo", "previous", "next", "refresh")
            val destination = if (direct) WidgetActionReceiver::class.java else WidgetWorkspaceActivity::class.java
            val intent = Intent(context, destination).apply {
                data = Uri.Builder().scheme("kutodo-widget").authority("workspace").appendPath(widgetId.toString())
                    .appendPath(action).appendPath(taskId ?: "").appendPath(selectedDate ?: "").build()
                putExtra("action", action); putExtra("task_id", taskId); putExtra("widget_id", widgetId); putExtra("kind", kind)
                putExtra("selected_date", selectedDate)
                addFlags(if (direct) Intent.FLAG_RECEIVER_FOREGROUND else Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            if (direct) return PendingIntent.getBroadcast(context, 0, intent, flags)
            val options = if (Build.VERSION.SDK_INT >= 34) ActivityOptions.makeBasic().apply {
                if (Build.VERSION.SDK_INT >= 35) setPendingIntentCreatorBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
                else @Suppress("DEPRECATION") setPendingIntentBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
            }.toBundle() else null
            return PendingIntent.getActivity(context, 0, intent, flags, options)
        }
    }
}

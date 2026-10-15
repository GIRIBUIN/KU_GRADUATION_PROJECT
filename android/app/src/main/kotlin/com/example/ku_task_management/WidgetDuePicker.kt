package com.example.ku_task_management

import android.app.TimePickerDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.MotionEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** A two-week viewport. Browsing weeks never changes the draft until a date is tapped. */
class WidgetDuePicker(
    context: Context, initial: Long?, private val palette: WidgetPalette, private val editable: Boolean = true,
    private val changed: (Long?) -> Unit,
) : LinearLayout(context) {
    private val zone = ZoneId.systemDefault()
    private var selected = initial?.let { Instant.ofEpochSecond(it).atZone(zone).toLocalDate() }
    private var time = initial?.let { Instant.ofEpochSecond(it).atZone(zone).toLocalTime() } ?: LocalTime.of(23, 59)
    private var start = sunday(selected ?: LocalDate.now()).minusWeeks(12)
    private val cells = mutableMapOf<LocalDate, TextView>()
    private var weekCount = 0
    private var ready = false
    private var initialized = false
    private val month = TextView(context)
    private val clock = Button(context)
    private val clear = Button(context)
    private val weeks = LinearLayout(context).apply { orientation = VERTICAL }
    private val viewport = ScrollView(context)

    init {
        tag = "widget_due_picker"; orientation = VERTICAL
        background = shape(palette.input, 12)
        setPadding(dp(6), dp(3), dp(6), dp(3))
        layoutParams = LayoutParams(-1, -2).apply { bottomMargin = dp(5) }
        val header = LinearLayout(context).apply { gravity = Gravity.CENTER_VERTICAL }
        month.apply { textSize = 12f; setTextColor(palette.text); maxLines = 1; tag = "widget_due_month" }
        header.addView(month, LayoutParams(0, dp(34), 1f).apply { gravity = Gravity.CENTER_VERTICAL })
        fun configure(button: Button, text: String, key: String) {
            button.text = text; button.tag = key; button.isAllCaps = false; button.textSize = 11f
            button.minimumWidth = 0; button.minimumHeight = 0; button.setPadding(0, 0, 0, 0)
            button.setTextColor(palette.accent); button.background = shape(palette.button, 8)
            button.stateListAnimator = null; button.elevation = 0f; button.isEnabled = editable
        }
        configure(clock, "시간", "widget_due_time")
        configure(clear, "기한 없음", "widget_due_none")
        header.addView(clock, LayoutParams(dp(62), dp(30)).apply { marginEnd = dp(4) })
        header.addView(clear, LayoutParams(dp(64), dp(30)))
        addView(header)
        val weekdays = LinearLayout(context)
        listOf("일", "월", "화", "수", "목", "금", "토").forEachIndexed { index, name ->
            weekdays.addView(TextView(context).apply {
                text = name; textSize = 10f; gravity = Gravity.CENTER
                setTextColor(if (index == 0) palette.red else if (index == 6) palette.accent else palette.muted)
            }, LayoutParams(0, dp(16), 1f))
        }
        addView(weekdays)
        viewport.apply {
            tag = "widget_due_viewport"; isFillViewport = false; isNestedScrollingEnabled = true
            setOnTouchListener { _, event ->
                parent?.requestDisallowInterceptTouchEvent(event.actionMasked !in setOf(MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL))
                false
            }
            addView(weeks)
        }
        addView(viewport, LayoutParams(-1, dp(72)))
        repeat(53) { appendWeek() }
        month.text = (selected ?: LocalDate.now()).format(DateTimeFormatter.ofPattern("yyyy년 M월"))
        refreshTime()
        viewport.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
            if (!initialized && viewport.height > 0 && weeks.height > 0) {
                initialized = true
                viewport.scrollTo(0, dp(12 * 36)); ready = true
            }
        }
        viewport.setOnScrollChangeListener { _, _, y, _, _ ->
            if (ready) {
                val visible = start.plusWeeks((y / dp(36)).toLong())
                month.text = visible.format(DateTimeFormatter.ofPattern("yyyy년 M월"))
                if (y + viewport.height >= weeks.height - dp(36)) repeat(12) { appendWeek() }
                if (y < dp(36)) {
                    ready = false
                    val earlier = start.minusWeeks(12)
                    repeat(12) { index -> weeks.addView(week(earlier.plusWeeks(index.toLong())), index) }
                    start = earlier; weekCount += 12
                    viewport.post { viewport.scrollTo(0, y + dp(12 * 36)); ready = true }
                }
            }
        }
        clear.setOnClickListener {
            val previous = selected; selected = null
            previous?.let { cells[it]?.let { cell -> style(cell, it) } }
            refreshTime(); changed(null)
        }
        clock.setOnClickListener {
            if (editable && selected != null) TimePickerDialog(context,
                if (palette.dark) R.style.WidgetPickerDialogDark else R.style.WidgetPickerDialog,
                { _, hour, minute -> time = LocalTime.of(hour, minute); refreshTime(); emit() }, time.hour, time.minute, true).show()
        }
    }

    private fun appendWeek() { weeks.addView(week(start.plusWeeks(weekCount.toLong()))); weekCount++ }

    private fun week(date: LocalDate) = LinearLayout(context).apply {
        layoutParams = LayoutParams(-1, dp(36))
        repeat(7) { index ->
            val day = date.plusDays(index.toLong())
            val cell = TextView(context).apply {
                tag = "widget_due_date_$day"; text = day.dayOfMonth.toString(); textSize = 13f
                gravity = Gravity.CENTER; isEnabled = editable
                setOnClickListener {
                    if (editable) {
                        val previous = selected; selected = day
                        previous?.let { cells[it]?.let { previousCell -> style(previousCell, it) } }
                        style(this, day); refreshTime(); emit()
                    }
                }
                isFocusable = false
            }
            cells[day] = cell; style(cell, day)
            addView(cell, LayoutParams(0, dp(36), 1f))
        }
    }

    private fun style(view: TextView, date: LocalDate) {
        val active = date == selected
        view.background = shape(if (active) palette.primary else Color.TRANSPARENT, 14)
        view.setTextColor(when {
            active -> Color.WHITE
            date.dayOfWeek.value == 7 -> palette.red
            date.dayOfWeek.value == 6 -> palette.accent
            else -> palette.text
        })
        view.setTypeface(null, if (date == LocalDate.now() || active) Typeface.BOLD else Typeface.NORMAL)
        view.contentDescription = "${date.year}년 ${date.monthValue}월 ${date.dayOfMonth}일" + if (active) ", 선택됨" else ""
    }

    private fun refreshTime() {
        clock.text = if (selected == null) "시간" else time.format(DateTimeFormatter.ofPattern("HH:mm"))
        clock.isEnabled = editable && selected != null
        clear.contentDescription = "기한 없음으로 설정"
    }
    private fun emit() { changed(selected?.atTime(time)?.atZone(zone)?.toEpochSecond()) }
    fun setDue(value: Long?) {
        val previous = selected
        selected = value?.let { Instant.ofEpochSecond(it).atZone(zone).toLocalDate() }
        value?.let { time = Instant.ofEpochSecond(it).atZone(zone).toLocalTime() }
        previous?.let { cells[it]?.let { cell -> style(cell, it) } }
        selected?.let { date -> cells[date]?.let { style(it, date) }
            viewport.smoothScrollTo(0, (java.time.temporal.ChronoUnit.DAYS.between(start, sunday(date)) / 7).toInt() * dp(36)) }
        refreshTime()
    }
    private fun sunday(date: LocalDate) = date.minusDays((date.dayOfWeek.value % 7).toLong())
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun shape(color: Int, radius: Int) = GradientDrawable().apply { setColor(color); cornerRadius = dp(radius).toFloat() }
}

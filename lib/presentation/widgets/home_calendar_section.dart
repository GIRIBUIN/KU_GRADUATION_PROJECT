import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';
import '../../data/services/calendar_task_index.dart';

class HomeCalendarSection extends StatefulWidget {
  const HomeCalendarSection({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.onCreateTask,
    required this.onOpenTask,
    required this.onToggleTask,
    required this.onDeleteTask,
    this.initialDay,
  });

  final List<Task> tasks;
  final bool isLoading;
  final ValueChanged<DateTime> onCreateTask;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onDeleteTask;
  final DateTime? initialDay;

  @override
  State<HomeCalendarSection> createState() => _HomeCalendarSectionState();
}

class _HomeCalendarSectionState extends State<HomeCalendarSection> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _format = CalendarFormat.month;
  CalendarTaskSource _source = CalendarTaskSource.all;
  bool _includeCompleted = true;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDay = calendarDay(widget.initialDay ?? DateTime.now());
    _focusedDay = _selectedDay;
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = calendarDay(day);
      _focusedDay = _selectedDay;
    });
  }

  Future<void> _pickDay(DateTime firstDay, DateTime lastDay) async {
    final day = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: firstDay,
      lastDate: lastDay,
    );
    if (day != null && mounted) _selectDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final index = CalendarTaskIndex.fromTasks(
      widget.tasks,
      includeCompleted: _includeCompleted,
      source: _source,
    );
    final days = [
      DateTime(2020),
      DateTime(2035, 12, 31),
      calendarDay(DateTime.now()),
      _focusedDay,
      _selectedDay,
      ...widget.tasks
          .map((task) => task.dueDate)
          .whereType<DateTime>()
          .map((date) => calendarDay(date.toLocal())),
    ]..sort();
    final firstDay = DateTime(days.first.year);
    final lastDay = DateTime(days.last.year, 12, 31);
    final selectedTasks = index.tasksForDay(_selectedDay);
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '캘린더',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: '선택한 날짜에 일정 추가',
              onPressed: () => widget.onCreateTask(_selectedDay),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: '이전 기간',
              onPressed: () => _pageController?.previousPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _pickDay(firstDay, lastDay),
                child: Text(
                  DateFormat('yyyy년 M월', 'ko_KR').format(_focusedDay),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              tooltip: '오늘로 이동',
              onPressed: () => _selectDay(DateTime.now()),
              icon: const Icon(Icons.today_rounded),
            ),
            IconButton(
              tooltip: '다음 기간',
              onPressed: () => _pageController?.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<CalendarFormat>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: CalendarFormat.month,
                  label: Text('월'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
                ButtonSegment(
                  value: CalendarFormat.week,
                  label: Text('주'),
                  icon: Icon(Icons.calendar_view_week_outlined),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) => setState(() {
                _format = selection.single;
                _focusedDay = _selectedDay;
              }),
            ),
            PopupMenuButton<CalendarTaskSource>(
              tooltip: '일정 유형: ${_sourceLabel(_source)}',
              initialValue: _source,
              onSelected: (value) => setState(() => _source = value),
              itemBuilder: (_) => [
                for (final source in CalendarTaskSource.values)
                  CheckedPopupMenuItem(
                    value: source,
                    checked: _source == source,
                    child: Text(_sourceLabel(source)),
                  ),
              ],
              icon: Icon(
                Icons.filter_list_rounded,
                color: _source == CalendarTaskSource.all
                    ? null
                    : colors.primary,
              ),
            ),
            IconButton(
              tooltip: _includeCompleted ? '완료 일정 숨기기' : '완료 일정 표시',
              isSelected: _includeCompleted,
              onPressed: () =>
                  setState(() => _includeCompleted = !_includeCompleted),
              icon: const Icon(Icons.check_circle_outline_rounded),
              selectedIcon: const Icon(Icons.check_circle_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TableCalendar<Task>(
          locale: 'ko_KR',
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (day, _) => _selectDay(day),
          onCalendarCreated: (controller) => _pageController = controller,
          onPageChanged: (day) =>
              setState(() => _focusedDay = calendarDay(day)),
          calendarFormat: _format,
          availableGestures: AvailableGestures.horizontalSwipe,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          sixWeekMonthsEnforced: true,
          rowHeight: 52 + (textScale - 1).clamp(0, 2) * 16,
          daysOfWeekHeight: 24 * textScale.clamp(1, 3),
          eventLoader: index.tasksForDay,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(3),
            selectedDecoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
            weekendTextStyle: const TextStyle(color: AppTheme.dangerRed),
          ),
          calendarBuilders: CalendarBuilders<Task>(
            defaultBuilder: (_, day, _) => _dayCell(day),
            selectedBuilder: (_, day, _) => _dayCell(day, selected: true),
            todayBuilder: (_, day, _) => _dayCell(day, today: true),
            disabledBuilder: (_, day, _) => _dayCell(day, disabled: true),
            markerBuilder: (context, day, tasks) {
              if (tasks.isEmpty) return null;
              return Positioned(
                bottom: 1,
                child: Semantics(
                  label: '${day.month}월 ${day.day}일 일정 ${tasks.length}개',
                  child: Row(
                    key: ValueKey(
                      'calendar-marker-${calendarDay(day).toIso8601String()}',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final origin
                          in tasks.map((task) => task.origin).toSet())
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: origin == TaskOrigin.ecampus
                                ? AppTheme.successGreen
                                : AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay)} · ${selectedTasks.length}개',
          key: const ValueKey('calendar-selected-day'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (selectedTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '등록된 일정이 없습니다.',
              style: TextStyle(color: AppTheme.muted),
            ),
          )
        else
          for (final task in selectedTasks) _taskTile(task),
        if (!widget.isLoading && index.undated.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('날짜 미지정 (${index.undated.length})'),
            children: [for (final task in index.undated) _taskTile(task)],
          ),
      ],
    );
  }

  Widget _dayCell(
    DateTime day, {
    bool selected = false,
    bool today = false,
    bool disabled = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 12),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? colors.primary
                  : today
                  ? colors.primary.withValues(alpha: 0.12)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 16,
                    color: selected
                        ? colors.onPrimary
                        : disabled
                        ? AppTheme.muted
                        : today
                        ? colors.primary
                        : weekend
                        ? AppTheme.dangerRed
                        : colors.onSurface,
                    fontWeight: today || selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskTile(Task task) {
    final completed = task.status == TaskStatus.completed;
    final dueDate = task.dueDate?.toLocal();
    return ListTile(
      key: ValueKey('calendar-task-${task.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: completed,
        semanticLabel: '${task.title} 완료',
        onChanged: (_) => widget.onToggleTask(task),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          if (dueDate != null) DateFormat('HH:mm').format(dueDate),
          task.origin == TaskOrigin.ecampus ? 'e-campus' : '개인',
          if (completed) '완료',
        ].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: '${task.title} 일정 메뉴',
        onSelected: (action) {
          if (action == 'delete') {
            widget.onDeleteTask(task);
          } else {
            widget.onOpenTask(task);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('수정'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline_rounded),
              title: Text('삭제'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: () => widget.onOpenTask(task),
    );
  }

  String _sourceLabel(CalendarTaskSource source) => switch (source) {
    CalendarTaskSource.all => '전체 일정',
    CalendarTaskSource.personal => '개인 일정',
    CalendarTaskSource.ecampus => 'e-campus 일정',
  };
}

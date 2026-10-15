import 'package:flutter/material.dart';

import '../../data/models/task_models.dart';
import '../../data/services/widget_workspace_controller.dart';

class WorkspaceCalendar extends StatelessWidget {
  const WorkspaceCalendar({
    super.key,
    required this.month,
    required this.tasks,
    required this.onDay,
    this.onMonth,
    this.adaptive = false,
  });
  final DateTime month;
  final List<Task> tasks;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<DateTime>? onMonth;
  final bool adaptive;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final now = DateTime.now();
      final first = DateTime(month.year, month.month);
      final start = first.subtract(Duration(days: first.weekday % 7));
      final total =
          ((first.weekday % 7 + DateTime(month.year, month.month + 1, 0).day) /
                  7)
              .ceil();
      final wide = constraints.maxWidth >= 320;
      final available = (constraints.maxHeight - 62).clamp(28.0, 10000.0);
      final count = adaptive
          ? (available ~/ (wide ? 50 : 30)).clamp(1, total)
          : total;
      final current =
          WidgetWorkspaceController.sameDay(
            DateTime(now.year, now.month),
            first,
          )
          ? now.difference(start).inDays ~/ 7
          : 0;
      final offset = (current - (count - 1) ~/ 2).clamp(0, total - count);
      final gridStart = start.add(Duration(days: offset * 7));
      return Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                if (onMonth != null)
                  IconButton(
                    tooltip: '이전 달',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30),
                    onPressed: () =>
                        onMonth!(DateTime(month.year, month.month - 1)),
                    icon: const Icon(Icons.chevron_left, size: 18),
                  ),
                Expanded(
                  child: Text(
                    constraints.maxWidth < 240
                        ? '${month.month}월'
                        : '${month.year}년 ${month.month}월',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onMonth != null)
                  IconButton(
                    tooltip: '다음 달',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30),
                    onPressed: () =>
                        onMonth!(DateTime(month.year, month.month + 1)),
                    icon: const Icon(Icons.chevron_right, size: 18),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 22,
            child: Row(
              children: [
                for (final name in ['일', '월', '화', '수', '목', '금', '토'])
                  Expanded(
                    child: Center(
                      child: Text(name, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (var week = 0; week < count; week++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var weekday = 0; weekday < 7; weekday++)
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final date = gridStart.add(
                                  Duration(days: week * 7 + weekday),
                                );
                                final matches = tasks
                                    .where(
                                      (task) =>
                                          task.dueDate != null &&
                                          WidgetWorkspaceController.sameDay(
                                            task.dueDate!,
                                            date,
                                          ),
                                    )
                                    .toList();
                                final today = WidgetWorkspaceController.sameDay(
                                  now,
                                  date,
                                );
                                return InkWell(
                                  onTap: () => onDay(date),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: today
                                            ? BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                shape: BoxShape.circle,
                                              )
                                            : null,
                                        child: Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: today
                                                ? Colors.white
                                                : date.month != month.month
                                                ? Theme.of(
                                                    context,
                                                  ).disabledColor
                                                : weekday == 0
                                                ? Colors.redAccent
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (matches.isNotEmpty &&
                                          wide &&
                                          available / count >= 50) ...[
                                        Text(
                                          matches.first.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        if (matches.length > 1)
                                          Text(
                                            '+${matches.length - 1}',
                                            style: const TextStyle(fontSize: 9),
                                          ),
                                      ] else if (matches.isNotEmpty)
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            height: .55,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class TwoWeekDuePicker extends StatefulWidget {
  const TwoWeekDuePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool readOnly;
  @override
  State<TwoWeekDuePicker> createState() => _TwoWeekDuePickerState();
}

class _TwoWeekDuePickerState extends State<TwoWeekDuePicker> {
  late final DateTime _start;
  late final ScrollController _scroll;
  late DateTime _visible;
  @override
  void initState() {
    super.initState();
    final anchor = widget.value ?? DateTime.now();
    _start = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
    ).subtract(Duration(days: anchor.weekday % 7 + 5200 * 7));
    _visible = anchor;
    _scroll = ScrollController(initialScrollOffset: 5200 * 36);
    _scroll.addListener(() {
      final date = _start.add(Duration(days: (_scroll.offset ~/ 36) * 7));
      if (_visible.month != date.month || _visible.year != date.year) {
        setState(() => _visible = date);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_visible.year}년 ${_visible.month}월',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: widget.readOnly || widget.value == null
                  ? null
                  : () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(widget.value!),
                      );
                      if (time != null) {
                        widget.onChanged(
                          DateTime(
                            widget.value!.year,
                            widget.value!.month,
                            widget.value!.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    },
              child: Text(
                widget.value == null
                    ? '시간'
                    : TimeOfDay.fromDateTime(widget.value!).format(context),
              ),
            ),
            TextButton(
              onPressed: widget.readOnly ? null : () => widget.onChanged(null),
              child: const Text('기한 없음'),
            ),
          ],
        ),
        SizedBox(
          height: 16,
          child: Row(
            children: [
              for (final name in ['일', '월', '화', '수', '목', '금', '토'])
                Expanded(
                  child: Center(
                    child: Text(name, style: const TextStyle(fontSize: 10)),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          key: const ValueKey('due-two-week-viewport'),
          height: 72,
          child: ListView.builder(
            controller: _scroll,
            itemExtent: 36,
            itemCount: 10401,
            itemBuilder: (context, week) => Row(
              children: [
                for (var day = 0; day < 7; day++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final date = _start.add(Duration(days: week * 7 + day));
                        final selected =
                            widget.value != null &&
                            WidgetWorkspaceController.sameDay(
                              date,
                              widget.value!,
                            );
                        return InkWell(
                          key: ValueKey(
                            'due-${date.year}-${date.month}-${date.day}',
                          ),
                          onTap: widget.readOnly
                              ? null
                              : () => widget.onChanged(
                                  DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    widget.value?.hour ?? 23,
                                    widget.value?.minute ?? 59,
                                  ),
                                ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: selected
                                  ? BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    )
                                  : null,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : day == 0
                                      ? Colors.redAccent
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.readOnly)
          const Text('학업 일정의 원본 마감은 유지됩니다.', style: TextStyle(fontSize: 11)),
      ],
    ),
  );
}

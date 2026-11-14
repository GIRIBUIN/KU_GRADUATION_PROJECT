import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';
import '../../data/services/home_task_summary.dart';

Widget buildTaskListRow({
  required Key key,
  required Task task,
  required Widget leading,
  required VoidCallback? onTap,
  VoidCallback? onLongPress,
  List<Folder> lists = const [],
  List<FolderGroup> groups = const [],
  List<Tag> tags = const [],
}) {
  final isExcluded = task.status == TaskStatus.excluded;
  final list = isExcluded
      ? null
      : lists.where((l) => l.id == task.listId).firstOrNull;
  final group = groups.where((g) => g.id == list?.groupId).firstOrNull;
  final path = [
    if (group != null) group.name,
    if (list != null) list.name,
  ].join(' > ');
  final details = [
    if (path.isNotEmpty) path,
    if (isExcluded && path.isEmpty && task.ecampus?.sourceCourse != null)
      task.ecampus!.sourceCourse!,
    for (final tag in tags.where((t) => task.tagIds.contains(t.id)))
      '#${tag.name}',
  ];
  final due = task.dueDate?.toLocal();
  final now = DateTime.now();
  final dueDays = due == null
      ? 0
      : DateTime.utc(
          due.year,
          due.month,
          due.day,
        ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  final dueLabel = dueDays == 0
      ? 'D-day'
      : dueDays > 0
      ? 'D-$dueDays'
      : 'D+${-dueDays}';
  final priorityColor = switch (task.priority) {
    TaskPriority.high => AppTheme.dangerRed,
    TaskPriority.medium => AppTheme.warningOrange,
    TaskPriority.low => AppTheme.primaryBlue,
    null => null,
  };
  final priorityLabel = switch (task.priority) {
    TaskPriority.high => '우선순위 높음',
    TaskPriority.medium => '우선순위 중간',
    TaskPriority.low => '우선순위 낮음',
    null => null,
  };
  final dueStyle = TextStyle(
    fontSize: 12,
    height: 1.1,
    color:
        task.status == TaskStatus.active &&
            due != null &&
            isDueDateOverdue(due, now: now)
        ? AppTheme.dangerRed
        : AppTheme.muted,
  );
  return Semantics(
    label: priorityLabel,
    child: Material(
      color: priorityColor?.withValues(alpha: .08) ?? Colors.transparent,
      child: ListTile(
        key: key,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: leading,
        onTap: onTap,
        onLongPress: onLongPress,
        title: Text(
          task.title,
          softWrap: true,
          style: TextStyle(
            fontSize: 13,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: details.isEmpty
            ? null
            : Text(
                details.join(' · '),
                softWrap: true,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (due == null)
              Text('마감 없음', style: dueStyle)
            else ...[
              Text(dueLabel, style: dueStyle),
              Text(DateFormat('HH:mm', 'ko_KR').format(due), style: dueStyle),
            ],
          ],
        ),
      ),
    ),
  );
}

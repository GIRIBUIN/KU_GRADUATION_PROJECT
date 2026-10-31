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
  final dueText = due == null
      ? '마감 없음'
      : DateFormat(
          due.year == DateTime.now().year &&
                  due.month == DateTime.now().month &&
                  due.day == DateTime.now().day
              ? 'HH:mm'
              : 'M/d HH:mm',
          'ko_KR',
        ).format(due);
  return ListTile(
    key: key,
    contentPadding: EdgeInsets.zero,
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          dueText,
          style: TextStyle(
            fontSize: 12,
            color:
                task.status == TaskStatus.active &&
                    due != null &&
                    isDueDateOverdue(due, now: DateTime.now())
                ? AppTheme.dangerRed
                : AppTheme.muted,
          ),
        ),
        if (task.priority != null)
          Text(
            switch (task.priority!) {
              TaskPriority.high => '높음',
              TaskPriority.medium => '중간',
              TaskPriority.low => '낮음',
            },
            style: TextStyle(
              fontSize: 10,
              color: task.priority == TaskPriority.high
                  ? AppTheme.warningOrange
                  : AppTheme.muted,
            ),
          ),
      ],
    ),
  );
}

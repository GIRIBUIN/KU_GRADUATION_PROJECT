import 'package:flutter/painting.dart' show Color;

import '../models/task_models.dart';

const widgetDefaultAccentColorHex = '#1262D6';
const widgetDueDangerColorHex = '#E72E2E';
const widgetDueSuccessColorHex = '#139A50';
const widgetDuePrimaryColorHex = '#1262D6';
const widgetDueWarningColorHex = '#F57C00';

const widgetCategoryEcampusBackgroundHex = '#EDE9FE';
const widgetCategoryEcampusTextHex = '#7C3AED';
const widgetCategoryPersonalBackgroundHex = '#FCE7F3';
const widgetCategoryPersonalTextHex = '#DB2777';

String formatWidgetHeaderDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[date.weekday - 1];
  return '${date.month}월 ${date.day}일 ($weekday)';
}

String formatWidgetTime(DateTime? dueDate) {
  if (dueDate == null) {
    return '--:--';
  }
  if (dueDate.hour == 0 && dueDate.minute == 0) {
    return '종일';
  }
  final hour = dueDate.hour.toString().padLeft(2, '0');
  final minute = dueDate.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String accentColorForTask(Task task, {required Map<String, Tag> tagsById}) {
  for (final tagId in task.tagIds) {
    final tag = tagsById[tagId];
    if (tag != null) {
      return normalizeWidgetColorHex(tag.color);
    }
  }
  return widgetDefaultAccentColorHex;
}

String formatWidgetWeekRange(DateTime weekStart, DateTime weekEnd) {
  return '${formatWidgetHeaderDate(weekStart)} ~ ${formatWidgetHeaderDate(weekEnd)}';
}

String formatWidgetProgressLabel({
  required int completedCount,
  required int totalCount,
}) {
  return '$completedCount / $totalCount 완료';
}

int dueDaysFromNow(DateTime dueDate, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  return dueDay.difference(today).inDays;
}

String formatWidgetDueLabel(DateTime dueDate, {required DateTime now}) {
  if (dueDate.isBefore(now) && dueDaysFromNow(dueDate, now: now) < 0) {
    final days = dueDaysFromNow(dueDate, now: now).abs();
    return days == 0 ? '마감 지남' : 'D+$days';
  }

  final days = dueDaysFromNow(dueDate, now: now);
  if (days == 0) {
    return 'D-day';
  }
  if (days > 0) {
    return 'D-$days';
  }
  return 'D+${days.abs()}';
}

String dueColorHexForDate(DateTime dueDate, {required DateTime now}) {
  final days = dueDaysFromNow(dueDate, now: now);
  if (days < 0 || dueDate.isBefore(now)) {
    return widgetDueDangerColorHex;
  }
  if (days == 0) {
    return widgetDueSuccessColorHex;
  }
  if (days <= 3) {
    return widgetDueWarningColorHex;
  }
  return widgetDuePrimaryColorHex;
}

Tag? _displayTag(Task task, Map<String, Tag> tagsById) {
  for (final id in task.tagIds) {
    final tag = tagsById[id];
    if (tag != null && tag.name.trim().isNotEmpty) return tag;
  }
  return null;
}

String categoryLabelForTask(Task task, {required Map<String, Tag> tagsById}) {
  return _displayTag(task, tagsById)?.name.trim() ?? '';
}

String categoryBackgroundHexForTask(
  Task task, {
  required Map<String, Tag> tagsById,
}) {
  final tag = _displayTag(task, tagsById);
  return tag == null ? '#E5E7EB' : normalizeWidgetColorHex(tag.color);
}

String categoryTextHexForTask(Task task, {required Map<String, Tag> tagsById}) {
  final background = categoryBackgroundHexForTask(task, tagsById: tagsById);
  final rgb = int.tryParse(background.replaceFirst('#', ''), radix: 16);
  if (rgb == null) return '#111827';
  final luminance = Color(0xFF000000 | rgb).computeLuminance();
  // Choose the stronger contrast against the actual stored tag color.
  return luminance > 0.179 ? '#000000' : '#FFFFFF';
}

String normalizeWidgetColorHex(String color) {
  final trimmed = color.trim();
  if (trimmed.isEmpty) {
    return widgetDefaultAccentColorHex;
  }
  return trimmed.startsWith('#') ? trimmed : '#$trimmed';
}

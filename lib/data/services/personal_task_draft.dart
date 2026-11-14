import '../models/task_models.dart';

/// Shared defaults for the normal editor and the widget quick editor.
Task personalTaskDraft({
  required String title,
  required DateTime now,
  DateTime? dueDate,
  Iterable<String> tagIds = const [],
  TaskPriority? priority,
  String? memo,
  String? listId,
}) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) throw ArgumentError('제목을 입력해주세요.');
  return Task(
    id: 'task_${now.microsecondsSinceEpoch}',
    origin: TaskOrigin.personal,
    status: TaskStatus.active,
    title: trimmed,
    dueDate: dueDate,
    tagIds: tagIds.toList(growable: false),
    priority: priority,
    memo: memo == null || memo.trim().isEmpty ? null : memo.trim(),
    folderIds: listId == null ? const [] : [listId],
    createdAt: now,
    updatedAt: now,
  );
}

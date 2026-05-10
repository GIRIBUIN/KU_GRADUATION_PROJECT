enum TaskOrigin { personal, ecampus }

enum TaskPriority { high, medium, low }

enum TaskStatus { active, completed, deleted, excluded }

enum EcampusTaskType { report, project, lecture, quiz, exam, unknown }

class Task {
  const Task({
    required this.id,
    required this.origin,
    required this.status,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.priority,
    this.memo,
    this.parentTaskId,
    this.tagIds = const [],
    this.folderIds = const [],
    this.ecampus,
    this.sortOrder = -1,
    this.completedAt,
    this.deletedAt,
  });

  final String id;
  final TaskOrigin origin;
  final TaskStatus status;
  final String title;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final String? memo;
  final String? parentTaskId;
  final List<String> tagIds;
  final List<String> folderIds;
  final EcampusSyncMetadata? ecampus;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  bool get isEcampus => origin == TaskOrigin.ecampus;

  bool get isArchived =>
      status == TaskStatus.completed ||
      status == TaskStatus.deleted ||
      status == TaskStatus.excluded;
}

class SubTask {
  const SubTask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.icon,
    this.parentFolderId,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? color;
  final String? icon;
  final String? parentFolderId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class NotificationSetting {
  const NotificationSetting({
    required this.id,
    required this.taskId,
    required this.enabled,
    required this.daysBeforeDue,
    required this.notifyTime,
    this.scheduledAt,
  });

  final String id;
  final String taskId;
  final bool enabled;
  final int daysBeforeDue;
  final String notifyTime;
  final DateTime? scheduledAt;
}

class EcampusSyncMetadata {
  const EcampusSyncMetadata({
    required this.sourceKey,
    this.sourceTitle,
    this.sourceDueDate,
    this.sourceCourse,
    this.sourceType,
    this.lastSyncedAt,
  });

  final String sourceKey;
  final String? sourceTitle;
  final DateTime? sourceDueDate;
  final String? sourceCourse;
  final EcampusTaskType? sourceType;
  final DateTime? lastSyncedAt;
}

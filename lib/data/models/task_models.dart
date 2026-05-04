import 'package:flutter/material.dart';

enum TaskSource { ecampus, personal }

enum TaskPriority { high, medium, low }

enum TaskStatus { active, completed, deleted, excluded }

class TaskTag {
  const TaskTag({
    required this.name,
    required this.color,
    required this.defaultPriority,
  });

  final String name;
  final Color color;
  final TaskPriority defaultPriority;
}

class TaskFolder {
  const TaskFolder({required this.name, required this.count});

  final String name;
  final int count;
}

class SubTask {
  const SubTask({required this.title, this.isDone = false});

  final String title;
  final bool isDone;
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.dueLabel,
    required this.source,
    required this.priority,
    required this.tags,
    this.status = TaskStatus.active,
    this.subTasks = const [],
    this.memo,
    this.sourceNote,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String dueLabel;
  final TaskSource source;
  final TaskPriority priority;
  final List<TaskTag> tags;
  final TaskStatus status;
  final List<SubTask> subTasks;
  final String? memo;
  final String? sourceNote;
  final bool isCompleted;

  int get doneSubTaskCount => subTasks.where((task) => task.isDone).length;

  double get progress {
    if (subTasks.isEmpty) {
      return isCompleted ? 1 : 0;
    }
    return doneSubTaskCount / subTasks.length;
  }
}

class SyncCandidate {
  const SyncCandidate({
    required this.title,
    required this.dueLabel,
    required this.statusLabel,
    required this.statusColor,
    this.isSelected = true,
    this.changeNote,
  });

  final String title;
  final String dueLabel;
  final String statusLabel;
  final Color statusColor;
  final bool isSelected;
  final String? changeNote;
}

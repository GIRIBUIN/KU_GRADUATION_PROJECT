import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';
import 'app_badge.dart';
import 'task_checkbox.dart';

Color priorityColor(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => AppTheme.dangerRed,
    TaskPriority.medium => AppTheme.warningOrange,
    TaskPriority.low => AppTheme.successGreen,
  };
}

String sourceLabel(TaskSource source) {
  return switch (source) {
    TaskSource.ecampus => 'e-campus',
    TaskSource.personal => '개인',
  };
}

Color sourceColor(TaskSource source) {
  return switch (source) {
    TaskSource.ecampus => AppTheme.primaryBlue,
    TaskSource.personal => AppTheme.successGreen,
  };
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskCheckbox(isChecked: task.isCompleted, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppBadge(
                          label: task.dueLabel,
                          color: AppTheme.successGreen,
                          icon: Icons.calendar_today_outlined,
                        ),
                        AppBadge(
                          label: sourceLabel(task.source),
                          color: sourceColor(task.source),
                        ),
                        for (final tag in task.tags.take(2))
                          AppBadge(label: tag.name, color: tag.color),
                      ],
                    ),
                    if (task.subTasks.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '서브 작업 ${task.doneSubTaskCount}/${task.subTasks.length} 완료',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${(task.progress * 100).round()}%',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(99),
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: AppTheme.successGreen,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: priorityColor(task.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.muted,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InlineTaskRow extends StatelessWidget {
  const InlineTaskRow({super.key, required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            const TaskCheckbox(size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppBadge(label: task.dueLabel, color: AppTheme.warningOrange),
            const SizedBox(width: 8),
            AppBadge(
              label: sourceLabel(task.source),
              color: sourceColor(task.source),
            ),
            const SizedBox(width: 10),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: priorityColor(task.priority),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

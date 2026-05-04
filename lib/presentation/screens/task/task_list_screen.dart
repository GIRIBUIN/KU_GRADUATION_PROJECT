import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/task_models.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/task_checkbox.dart';
import '../../widgets/task_widgets.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목록'),
        actions: [
          IconButton(
            tooltip: '필터',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: '작업 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: '검색 지우기',
                onPressed: () {},
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _FilterBar(),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '마감일순',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 6),
              Icon(Icons.swap_vert_rounded),
            ],
          ),
          const SizedBox(height: 12),
          _ExpandedTaskTile(task: MockData.tasks[0]),
          for (final task in MockData.tasks.skip(1)) _TaskListTile(task: task),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '개인 할 일 추가',
        onPressed: () {},
        backgroundColor: AppTheme.successGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 34),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    const filters = ['전체', 'e-campus', '개인', '미완료', '완료', '삭제됨'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            ChoiceChip(
              label: Text(filter),
              selected: filter == '전체',
              showCheckmark: false,
              selectedColor: AppTheme.successGreen,
              labelStyle: TextStyle(
                color: filter == '전체' ? Colors.white : AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) {},
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _ExpandedTaskTile extends StatelessWidget {
  const _ExpandedTaskTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.keyboard_arrow_down_rounded),
                ),
                const SizedBox(width: 8),
                const TaskCheckbox(size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppBadge(
                            label: task.dueLabel,
                            color: AppTheme.successGreen,
                          ),
                          AppBadge(
                            label: sourceLabel(task.source),
                            color: sourceColor(task.source),
                          ),
                          Text(
                            '서브 작업 ${task.doneSubTaskCount}/${task.subTasks.length} 완료',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _TrailingMeta(task: task),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 72),
              child: Column(
                children: [
                  for (final subTask in task.subTasks.take(2))
                    _SubTaskRow(subTask: subTask, dueLabel: task.dueLabel),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('서브 작업 추가'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TaskCheckbox(size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppBadge(
                        label: task.dueLabel,
                        color: AppTheme.successGreen,
                      ),
                      AppBadge(
                        label: sourceLabel(task.source),
                        color: sourceColor(task.source),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _TrailingMeta(task: task),
          ],
        ),
      ),
    );
  }
}

class _TrailingMeta extends StatelessWidget {
  const _TrailingMeta({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tag in task.tags.take(2)) ...[
          AppBadge(label: tag.name, color: tag.color),
          const SizedBox(width: 7),
        ],
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: priorityColor(task.priority),
            shape: BoxShape.circle,
          ),
        ),
        IconButton(
          tooltip: '작업 메뉴',
          onPressed: () {},
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }
}

class _SubTaskRow extends StatelessWidget {
  const _SubTaskRow({required this.subTask, required this.dueLabel});

  final SubTask subTask;
  final String dueLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          TaskCheckbox(size: 24, isChecked: subTask.isDone),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subTask.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          AppBadge(label: dueLabel, color: AppTheme.successGreen),
          const SizedBox(width: 8),
          const AppBadge(label: 'e-campus', color: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}

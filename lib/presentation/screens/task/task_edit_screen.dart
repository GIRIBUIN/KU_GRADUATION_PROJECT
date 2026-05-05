import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/task_models.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/task_checkbox.dart';
import '../../widgets/task_widgets.dart';

class TaskEditScreen extends StatelessWidget {
  const TaskEditScreen({super.key, this.task});

  final TaskItem? task;

  @override
  Widget build(BuildContext context) {
    final currentTask = task ?? MockData.tasks.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('작업 수정'),
        actions: [
          IconButton(
            tooltip: '더보기',
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          TextFormField(
            initialValue: currentTask.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school_outlined, color: AppTheme.muted),
              const SizedBox(width: 8),
              Text(
                currentTask.sourceNote ??
                    '${sourceLabel(currentTask.source)} 작업',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingGroup(
            children: [
              _SettingRow(
                icon: Icons.calendar_month_outlined,
                color: AppTheme.successGreen,
                title: '마감일',
                value: '${currentTask.dueLabel} 23:59',
              ),
              const _SettingRow(
                icon: Icons.flag_rounded,
                color: AppTheme.dangerRed,
                title: '우선순위',
                value: '높음',
                valueColor: AppTheme.dangerRed,
              ),
              _TagSettingRow(task: currentTask),
              const _SettingRow(
                icon: Icons.notifications_none_rounded,
                color: AppTheme.warningOrange,
                title: '알림',
                value: '마감 1일 전 오전 9시',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            '서브 작업',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final subTask in currentTask.subTasks) ...[
                  _EditableSubTaskRow(subTask: subTask),
                  if (subTask != currentTask.subTasks.last)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('서브 작업 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.successGreen,
              side: const BorderSide(color: AppTheme.line),
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '메모',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: currentTask.memo ?? '',
            maxLines: 4,
            decoration: const InputDecoration(hintText: '메모를 입력하세요'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('삭제'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRed,
                  side: const BorderSide(color: AppTheme.dangerRed),
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('저장'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final child in children) ...[
            child,
            if (child != children.last)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _TagSettingRow extends StatelessWidget {
  const _TagSettingRow({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          const Icon(
            Icons.sell_outlined,
            color: AppTheme.primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '태그',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final tag in task.tags.take(2)) ...[
            AppBadge(label: tag.name, color: tag.color),
            const SizedBox(width: 8),
          ],
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(42, 34),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _EditableSubTaskRow extends StatelessWidget {
  const _EditableSubTaskRow({required this.subTask});

  final SubTask subTask;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator_rounded, color: AppTheme.muted),
          const SizedBox(width: 10),
          TaskCheckbox(isChecked: subTask.isDone, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              subTask.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: '서브 작업 메뉴',
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}

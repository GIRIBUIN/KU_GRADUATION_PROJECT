import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/sub_task_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/sub_task_progress.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.taskRepository,
    required this.subTaskRepository,
  });

  final String taskId;
  final TaskRepository taskRepository;
  final SubTaskRepository subTaskRepository;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _subTaskController = TextEditingController();

  Task? _task;
  List<SubTask> _subTasks = const [];
  DateTime? _dueDate;
  TaskPriority? _priority;
  var _isLoading = true;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final task = await widget.taskRepository.getTaskById(widget.taskId);
    final subTasks = await widget.subTaskRepository.getSubTasks(widget.taskId);

    if (!mounted) {
      return;
    }

    setState(() {
      _task = task;
      _subTasks = subTasks;
      _titleController.text = task?.title ?? '';
      _memoController.text = task?.memo ?? '';
      _dueDate = task?.dueDate;
      _priority = task?.priority;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;

    return Scaffold(
      appBar: AppBar(
        title: const Text('작업 상세'),
        actions: [
          TextButton(
            onPressed: task == null || _isSaving ? null : _saveTask,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : task == null
            ? const _MissingTaskView()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '제목'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  _DetailSection(
                    title: '일정',
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.event_rounded,
                          title: '마감일',
                          value: _dueDate == null
                              ? '없음'
                              : _dateTimeLabel(_dueDate!),
                          onTap: _pickDueDate,
                        ),
                        const Divider(height: 1),
                        _PrioritySelector(
                          value: _priority,
                          onChanged: (priority) {
                            setState(() {
                              _priority = priority;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _memoController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '메모',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SubTaskSection(
                    subTasks: _subTasks,
                    controller: _subTaskController,
                    onAdd: _addSubTask,
                    onToggle: _toggleSubTask,
                    onDelete: _deleteSubTask,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveTask() async {
    final task = _task;
    if (task == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final updated = Task(
      id: task.id,
      origin: task.origin,
      status: task.status,
      title: _titleController.text.trim().isEmpty
          ? task.title
          : _titleController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      parentTaskId: task.parentTaskId,
      tagIds: task.tagIds,
      folderIds: task.folderIds,
      ecampus: task.ecampus,
      sortOrder: task.sortOrder,
      createdAt: task.createdAt,
      updatedAt: now,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
    );

    await widget.taskRepository.updateTask(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _task = updated;
      _isSaving = false;
    });
    _showSnackBar(context, '작업을 저장했습니다.');
  }

  Future<void> _pickDueDate() async {
    final initial = _dueDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  Future<void> _addSubTask() async {
    final title = _subTaskController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final now = DateTime.now();
    await widget.subTaskRepository.createSubTask(
      SubTask(
        id: 'sub_${widget.taskId}_${now.microsecondsSinceEpoch}',
        taskId: widget.taskId,
        title: title,
        isDone: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _subTaskController.clear();
    await _reloadSubTasks();
  }

  Future<void> _toggleSubTask(SubTask subTask) async {
    await widget.subTaskRepository.updateSubTaskDone(
      subTask.id,
      !subTask.isDone,
    );
    await _reloadSubTasks();
  }

  Future<void> _deleteSubTask(SubTask subTask) async {
    await widget.subTaskRepository.deleteSubTask(subTask.id);
    await _reloadSubTasks();
  }

  Future<void> _reloadSubTasks() async {
    final subTasks = await widget.subTaskRepository.getSubTasks(widget.taskId);
    if (!mounted) {
      return;
    }

    setState(() {
      _subTasks = subTasks;
    });
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Card(clipBehavior: Clip.antiAlias, child: child),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});

  final TaskPriority? value;
  final ValueChanged<TaskPriority?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.flag_rounded, color: AppTheme.warningOrange),
      title: const Text('우선순위', style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('높음'),
              selected: value == TaskPriority.high,
              onSelected: (_) => onChanged(TaskPriority.high),
            ),
            ChoiceChip(
              label: const Text('보통'),
              selected: value == TaskPriority.medium,
              onSelected: (_) => onChanged(TaskPriority.medium),
            ),
            ChoiceChip(
              label: const Text('낮음'),
              selected: value == TaskPriority.low,
              onSelected: (_) => onChanged(TaskPriority.low),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTaskSection extends StatelessWidget {
  const _SubTaskSection({
    required this.subTasks,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<SubTask> subTasks;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<SubTask> onToggle;
  final ValueChanged<SubTask> onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = calculateSubTaskProgress(subTasks);

    return _DetailSection(
      title: '서브 작업',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          children: [
            if (progress.hasSubTasks) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${progress.doneCount}/${progress.totalCount} 완료',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('${progress.percent}%'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.ratio,
                minHeight: 6,
                backgroundColor: AppTheme.line,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final subTask in subTasks)
              CheckboxListTile(
                value: subTask.isDone,
                onChanged: (_) => onToggle(subTask),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  subTask.title,
                  style: TextStyle(
                    decoration: subTask.isDone
                        ? TextDecoration.lineThrough
                        : null,
                    color: subTask.isDone ? AppTheme.muted : AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                secondary: IconButton(
                  onPressed: () => onDelete(subTask),
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: '삭제',
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: '서브 작업 추가'),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '추가',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingTaskView extends StatelessWidget {
  const _MissingTaskView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('작업을 찾을 수 없습니다.'));
  }
}

String _dateTimeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}.${date.day} $hour:$minute';
}

void _showSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
}

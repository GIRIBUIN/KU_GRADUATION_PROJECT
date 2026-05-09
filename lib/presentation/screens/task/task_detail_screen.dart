import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/sub_task_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/sub_task_progress.dart';
import '../../services/local_notification_service.dart';
import '../../widgets/task_metadata_picker.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.taskRepository,
    required this.subTaskRepository,
    required this.notificationRepository,
    required this.tagRepository,
    required this.folderRepository,
    required this.localNotificationService,
  });

  final String taskId;
  final TaskRepository taskRepository;
  final SubTaskRepository subTaskRepository;
  final NotificationRepository notificationRepository;
  final TagRepository tagRepository;
  final FolderRepository folderRepository;
  final LocalNotificationService localNotificationService;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _subTaskController = TextEditingController();

  Task? _task;
  List<SubTask> _subTasks = const [];
  List<Tag> _tags = const [];
  List<Folder> _folders = const [];
  final Set<String> _selectedTagIds = {};
  String? _selectedFolderId;
  DateTime? _dueDate;
  TaskPriority? _priority;
  NotificationSetting? _notification;
  var _notificationEnabled = false;
  var _notificationOffsetMinutes = 60;
  var _isLoading = true;
  var _isSaving = false;
  var _didPopAfterSave = false;

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
    final notification = await widget.notificationRepository.getByTaskId(
      widget.taskId,
    );
    final tags = await widget.tagRepository.getTags();
    final folders = await widget.folderRepository.getFolders();

    if (!mounted) {
      return;
    }

    setState(() {
      _task = task;
      _subTasks = subTasks;
      _tags = tags;
      _folders = folders;
      _selectedTagIds
        ..clear()
        ..addAll(task?.tagIds ?? const []);
      _selectedFolderId = task?.folderIds.firstOrNull;
      _titleController.text = task?.title ?? '';
      _memoController.text = task?.memo ?? '';
      _dueDate = task?.dueDate;
      _priority = task?.priority;
      _notification = notification;
      _notificationEnabled = notification?.enabled ?? false;
      _notificationOffsetMinutes = notification?.daysBeforeDue ?? 60;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _didPopAfterSave) {
          return;
        }
        await _saveTask(popAfterSave: true, showMessage: false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('작업 상세'),
          actions: [
            TextButton(
              onPressed: task == null || _isSaving
                  ? null
                  : () => _saveTask(popAfterSave: true),
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
                    _DetailSection(
                      title: '알림',
                      child: Column(
                        children: [
                          _SwitchTile(
                            icon: Icons.notifications_rounded,
                            title: '작업 알림',
                            subtitle: _notificationEnabled
                                ? _notificationOffsetLabel(
                                    _notificationOffsetMinutes,
                                  )
                                : '꺼짐',
                            value: _notificationEnabled,
                            onChanged: (value) {
                              if (value) {
                                widget.localNotificationService
                                    .requestPermission();
                              }
                              setState(() {
                                _notificationEnabled = value;
                              });
                            },
                          ),
                          if (_notificationEnabled) ...[
                            const Divider(height: 1),
                            _ActionTile(
                              icon: Icons.schedule_rounded,
                              title: '알림 시점',
                              value: _notificationOffsetLabel(
                                _notificationOffsetMinutes,
                              ),
                              onTap: _pickNotificationOffset,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    TagPickerSection(
                      tags: _tags,
                      selectedIds: _selectedTagIds,
                      onToggle: _toggleTag,
                      onAdd: _createTag,
                    ),
                    const SizedBox(height: 22),
                    FolderPickerSection(
                      folders: _folders,
                      selectedId: _selectedFolderId,
                      onSelect: _selectFolder,
                      onAdd: _createFolder,
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
      ),
    );
  }

  Future<void> _saveTask({
    bool popAfterSave = false,
    bool showMessage = true,
  }) async {
    final task = _task;
    if (task == null) {
      if (popAfterSave && mounted) {
        _popWithSavedResult();
      }
      return;
    }
    if (_isSaving) {
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
      tagIds: _selectedTagIds.toList(growable: false),
      folderIds: _selectedFolderId == null ? const [] : [_selectedFolderId!],
      ecampus: task.ecampus,
      sortOrder: task.sortOrder,
      createdAt: task.createdAt,
      updatedAt: now,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
    );

    await widget.taskRepository.updateTask(updated);
    final notification = await widget.notificationRepository.save(
      NotificationSetting(
        id: _notification?.id ?? 'notification_${task.id}',
        taskId: task.id,
        enabled: _notificationEnabled,
        daysBeforeDue: _notificationOffsetMinutes,
        notifyTime: 'relative',
        scheduledAt: _notification?.scheduledAt,
      ),
    );
    await widget.localNotificationService.scheduleTaskNotification(
      task: updated,
      setting: notification,
      requestPermissionBeforeScheduling: _notificationEnabled,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _task = updated;
      _notification = notification;
      _isSaving = false;
    });
    if (popAfterSave) {
      _popWithSavedResult();
      return;
    }
    if (showMessage) {
      _showSnackBar(context, '작업을 저장했습니다.');
    }
  }

  void _popWithSavedResult() {
    _didPopAfterSave = true;
    Navigator.of(context).pop(true);
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

  Future<void> _pickNotificationOffset() async {
    final minutes = await _pickNotificationOffsetMinutes(
      context: context,
      title: '알림 시점',
      selected: _notificationOffsetMinutes,
    );
    if (minutes != null) {
      setState(() {
        _notificationOffsetMinutes = minutes;
      });
    }
  }

  Future<void> _addSubTask() async {
    final title = _subTaskController.text.trim();
    if (title.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();

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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서브 작업 삭제'),
        content: Text('"${subTask.title}"을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      return;
    }

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

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selectedTagIds.contains(tag.id)) {
        _selectedTagIds.remove(tag.id);
      } else {
        _selectedTagIds.add(tag.id);
      }
    });
  }

  void _selectFolder(Folder? folder) {
    setState(() {
      _selectedFolderId = folder?.id;
    });
  }

  Future<void> _createTag() async {
    final draft = await showTagCreateDialog(context);
    if (draft == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    final tag = await widget.tagRepository.createTag(
      Tag(
        id: 'tag_${now.microsecondsSinceEpoch}',
        name: draft.name,
        color: draft.color,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tags = [..._tags, tag]..sort((a, b) => a.name.compareTo(b.name));
      _selectedTagIds.add(tag.id);
    });
  }

  Future<void> _createFolder() async {
    final draft = await showFolderCreateDialog(context, folders: _folders);
    if (draft == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    final folder = await widget.folderRepository.createFolder(
      Folder(
        id: 'folder_${now.microsecondsSinceEpoch}',
        name: draft.name,
        color: draft.color,
        icon: 'folder',
        parentFolderId: draft.parentFolderId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _folders = [..._folders, folder]
        ..sort((a, b) => a.name.compareTo(b.name));
      _selectedFolderId = folder.id;
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final String? subtitle;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Switch(value: value, onChanged: onChanged),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('없음'),
                selected: value == null,
                onSelected: (_) => onChanged(null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('높음'),
                selected: value == TaskPriority.high,
                onSelected: (_) => onChanged(TaskPriority.high),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('보통'),
                selected: value == TaskPriority.medium,
                onSelected: (_) => onChanged(TaskPriority.medium),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('낮음'),
                selected: value == TaskPriority.low,
                onSelected: (_) => onChanged(TaskPriority.low),
              ),
            ],
          ),
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
            if (subTasks.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.line),
                ),
                child: const Text(
                  '아직 서브 작업이 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else
              for (var i = 0; i < subTasks.length; i++) ...[
                _SubTaskTile(
                  subTask: subTasks[i],
                  onToggle: () => onToggle(subTasks[i]),
                  onDelete: () => onDelete(subTasks[i]),
                ),
                if (i != subTasks.length - 1) const Divider(height: 1),
              ],
            if (subTasks.isNotEmpty) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '서브 작업 추가',
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
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

class _SubTaskTile extends StatelessWidget {
  const _SubTaskTile({
    required this.subTask,
    required this.onToggle,
    required this.onDelete,
  });

  final SubTask subTask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Checkbox(value: subTask.isDone, onChanged: (_) => onToggle()),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                subTask.title,
                style: TextStyle(
                  decoration: subTask.isDone
                      ? TextDecoration.lineThrough
                      : null,
                  color: subTask.isDone ? AppTheme.muted : AppTheme.ink,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppTheme.muted,
              tooltip: '삭제',
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

Future<int?> _pickNotificationOffsetMinutes({
  required BuildContext context,
  required String title,
  required int selected,
}) {
  var current = _closestNotificationOffset(selected);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final option in _notificationOffsetOptions)
                        ListTile(
                          onTap: () {
                            setSheetState(() {
                              current = option;
                            });
                          },
                          title: Text(_notificationOffsetLabel(option)),
                          trailing: current == option
                              ? const Icon(Icons.check_rounded)
                              : null,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(current),
                      child: const Text('적용'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

const _notificationOffsetOptions = [
  0,
  10,
  20,
  30,
  60,
  180,
  360,
  720,
  1440,
  4320,
];

int _closestNotificationOffset(int value) {
  var closest = _notificationOffsetOptions.first;
  for (final option in _notificationOffsetOptions) {
    final currentDistance = (option - value).abs();
    final closestDistance = (closest - value).abs();
    if (currentDistance < closestDistance) {
      closest = option;
    }
  }
  return closest;
}

String _notificationOffsetLabel(int minutes) {
  if (minutes == 0) {
    return '마감 시각';
  }
  if (minutes < 60) {
    return '마감 $minutes분 전';
  }
  if (minutes < 24 * 60) {
    final hours = minutes ~/ 60;
    return '마감 $hours시간 전';
  }
  final days = minutes ~/ (24 * 60);
  return '마감 $days일 전';
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

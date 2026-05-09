import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/sub_task_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/sub_task_progress.dart';
import '../../services/local_notification_service.dart';
import '../../widgets/task_metadata_picker.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({
    super.key,
    required this.taskRepository,
    required this.subTaskRepository,
    required this.notificationRepository,
    required this.settingsRepository,
    required this.tagRepository,
    required this.folderRepository,
    required this.localNotificationService,
  });

  final TaskRepository taskRepository;
  final SubTaskRepository subTaskRepository;
  final NotificationRepository notificationRepository;
  final SettingsRepository settingsRepository;
  final TagRepository tagRepository;
  final FolderRepository folderRepository;
  final LocalNotificationService localNotificationService;

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _subTaskController = TextEditingController();
  final List<_DraftSubTask> _subTasks = [];
  List<Tag> _tags = const [];
  List<Folder> _folders = const [];
  final Set<String> _selectedTagIds = {};
  String? _selectedFolderId;

  DateTime? _dueDate;
  TaskPriority? _priority;
  var _notificationEnabled = true;
  var _notificationOffsetMinutes = 60;
  var _isLoadingSettings = true;
  var _isSaving = false;
  var _didPopAfterSave = false;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final settings = await widget.settingsRepository.getSettings();
    final tags = await widget.tagRepository.getTags();
    final folders = await widget.folderRepository.getFolders();
    if (!mounted) {
      return;
    }
    setState(() {
      _tags = tags;
      _folders = folders;
      _notificationEnabled = settings.defaultNotificationEnabled;
      _notificationOffsetMinutes = settings.defaultNotificationDays;
      _isLoadingSettings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _didPopAfterSave) {
          return;
        }
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('새 작업'),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveTask,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '제목'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              _CreateSection(
                title: '일정',
                child: Column(
                  children: [
                    _CreateActionTile(
                      icon: Icons.event_rounded,
                      title: '마감일',
                      value: _dueDate == null
                          ? '없음'
                          : _dateTimeLabel(_dueDate!),
                      onTap: _pickDueDate,
                    ),
                    const Divider(height: 1),
                    _CreatePrioritySelector(
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
              _CreateSection(
                title: '알림',
                child: Column(
                  children: [
                    _CreateSwitchTile(
                      icon: Icons.notifications_rounded,
                      title: '작업 알림',
                      subtitle: _notificationEnabled
                          ? _notificationOffsetLabel(_notificationOffsetMinutes)
                          : '꺼짐',
                      value: _notificationEnabled,
                      onChanged: _isLoadingSettings
                          ? null
                          : (value) {
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
                      _CreateActionTile(
                        icon: Icons.schedule_rounded,
                        title: '알림 시점',
                        value: _notificationOffsetLabel(
                          _notificationOffsetMinutes,
                        ),
                        onTap: _isLoadingSettings
                            ? null
                            : _pickNotificationOffset,
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
              _DraftSubTaskSection(
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

  Future<void> _handleBack() async {
    if (!_hasDraftInput()) {
      _popWithoutResult();
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작업 생성을 취소할까요?'),
        content: const Text('입력한 내용은 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 작성'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (shouldLeave == true && mounted) {
      _popWithoutResult();
    }
  }

  bool _hasDraftInput() {
    return _titleController.text.trim().isNotEmpty ||
        _memoController.text.trim().isNotEmpty ||
        _dueDate != null ||
        _priority != null ||
        _subTasks.isNotEmpty ||
        _selectedTagIds.isNotEmpty ||
        _selectedFolderId != null;
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar(context, '제목을 입력해주세요.');
      return;
    }
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final taskId = 'task_${now.microsecondsSinceEpoch}';
    final task = await widget.taskRepository.createTask(
      Task(
        id: taskId,
        origin: TaskOrigin.personal,
        status: TaskStatus.active,
        title: title,
        dueDate: _dueDate,
        priority: _priority,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        tagIds: _selectedTagIds.toList(growable: false),
        folderIds: _selectedFolderId == null ? const [] : [_selectedFolderId!],
        createdAt: now,
        updatedAt: now,
      ),
    );

    for (var index = 0; index < _subTasks.length; index++) {
      final subTask = _subTasks[index];
      await widget.subTaskRepository.createSubTask(
        SubTask(
          id: 'sub_${task.id}_${now.microsecondsSinceEpoch}_$index',
          taskId: task.id,
          title: subTask.title,
          isDone: subTask.isDone,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final notification = await widget.notificationRepository.save(
      NotificationSetting(
        id: 'notification_${task.id}',
        taskId: task.id,
        enabled: _notificationEnabled,
        daysBeforeDue: _notificationOffsetMinutes,
        notifyTime: 'relative',
      ),
    );
    await widget.localNotificationService.scheduleTaskNotification(
      task: task,
      setting: notification,
      requestPermissionBeforeScheduling: _notificationEnabled,
    );

    if (!mounted) {
      return;
    }

    _didPopAfterSave = true;
    Navigator.of(context).pop(true);
  }

  void _popWithoutResult() {
    _didPopAfterSave = true;
    Navigator.of(context).pop(false);
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

  void _addSubTask() {
    final title = _subTaskController.text.trim();
    if (title.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _subTasks.add(_DraftSubTask(title: title));
      _subTaskController.clear();
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

  void _toggleSubTask(_DraftSubTask subTask) {
    setState(() {
      final index = _subTasks.indexOf(subTask);
      if (index < 0) {
        return;
      }
      _subTasks[index] = subTask.copyWith(isDone: !subTask.isDone);
    });
  }

  void _deleteSubTask(_DraftSubTask subTask) {
    setState(() {
      _subTasks.remove(subTask);
    });
  }
}

class _DraftSubTask {
  const _DraftSubTask({required this.title, this.isDone = false});

  final String title;
  final bool isDone;

  _DraftSubTask copyWith({bool? isDone}) {
    return _DraftSubTask(title: title, isDone: isDone ?? this.isDone);
  }
}

class _CreateSection extends StatelessWidget {
  const _CreateSection({required this.title, required this.child});

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

class _CreateActionTile extends StatelessWidget {
  const _CreateActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

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

class _CreateSwitchTile extends StatelessWidget {
  const _CreateSwitchTile({
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

class _CreatePrioritySelector extends StatelessWidget {
  const _CreatePrioritySelector({required this.value, required this.onChanged});

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

class _DraftSubTaskSection extends StatelessWidget {
  const _DraftSubTaskSection({
    required this.subTasks,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<_DraftSubTask> subTasks;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<_DraftSubTask> onToggle;
  final ValueChanged<_DraftSubTask> onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = calculateSubTaskProgress([
      for (var index = 0; index < subTasks.length; index++)
        SubTask(
          id: 'draft_$index',
          taskId: 'draft',
          title: subTasks[index].title,
          isDone: subTasks[index].isDone,
          createdAt: DateTime(0),
          updatedAt: DateTime(0),
        ),
    ]);

    return _CreateSection(
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
                  '서브 작업을 추가해 작업을 작게 나눌 수 있습니다.',
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
                _DraftSubTaskTile(
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

class _DraftSubTaskTile extends StatelessWidget {
  const _DraftSubTaskTile({
    required this.subTask,
    required this.onToggle,
    required this.onDelete,
  });

  final _DraftSubTask subTask;
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

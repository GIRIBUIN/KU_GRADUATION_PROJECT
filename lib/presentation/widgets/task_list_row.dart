import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';
import '../../data/repositories/sub_task_repository.dart';
import '../../data/services/home_task_summary.dart';

Widget buildTaskListRow({
  required Key key,
  required Task task,
  required Widget leading,
  required VoidCallback? onTap,
  VoidCallback? onLongPress,
  List<Folder> lists = const [],
  List<FolderGroup> groups = const [],
  List<Tag> tags = const [],
  SubTaskRepository? subTaskRepository,
  int subTaskVersion = 0,
  VoidCallback? onSubTasksChanged,
}) => _TaskListRow(
  key: ValueKey(('task-row', key)),
  rowKey: key,
  task: task,
  leading: leading,
  onTap: onTap,
  onLongPress: onLongPress,
  lists: lists,
  groups: groups,
  tags: tags,
  subTaskRepository: subTaskRepository,
  subTaskVersion: subTaskVersion,
  onSubTasksChanged: onSubTasksChanged,
);

class _TaskListRow extends StatefulWidget {
  const _TaskListRow({
    super.key,
    required this.rowKey,
    required this.task,
    required this.leading,
    required this.onTap,
    required this.onLongPress,
    required this.lists,
    required this.groups,
    required this.tags,
    required this.subTaskRepository,
    required this.subTaskVersion,
    required this.onSubTasksChanged,
  });
  final Key rowKey;
  final Task task;
  final Widget leading;
  final VoidCallback? onTap, onLongPress, onSubTasksChanged;
  final List<Folder> lists;
  final List<FolderGroup> groups;
  final List<Tag> tags;
  final SubTaskRepository? subTaskRepository;
  final int subTaskVersion;
  @override
  State<_TaskListRow> createState() => _TaskListRowState();
}

class _TaskListRowState extends State<_TaskListRow> {
  List<SubTask> _subTasks = const [];
  bool _expanded = false;
  bool _saving = false;
  bool _loadFailed = false;
  int _loadVersion = 0;
  Future<void>? _pendingLoad;
  bool get _canExpand =>
      widget.subTaskRepository != null &&
      widget.task.status != TaskStatus.deleted &&
      widget.task.status != TaskStatus.excluded;
  bool get _hasSubTasks => _canExpand && _subTasks.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pendingLoad = _loadSubTasks();
  }

  @override
  void didUpdateWidget(covariant _TaskListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != oldWidget.task ||
        widget.subTaskRepository != oldWidget.subTaskRepository ||
        widget.subTaskVersion != oldWidget.subTaskVersion) {
      _pendingLoad = _loadSubTasks();
    }
  }

  Future<void> _loadSubTasks() async {
    final version = ++_loadVersion;
    if (!_canExpand) {
      _subTasks = const [];
      _expanded = false;
      _loadFailed = false;
      return;
    }
    try {
      final subTasks = await widget.subTaskRepository!.getSubTasks(
        widget.task.id,
      );
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _subTasks = subTasks;
        _loadFailed = false;
        if (subTasks.isEmpty) _expanded = false;
      });
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _handleTap() async {
    await _pendingLoad;
    if (!mounted) return;
    if (_loadFailed) {
      _pendingLoad = _loadSubTasks();
      await _pendingLoad;
      if (!mounted) return;
      if (_loadFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서브 작업을 불러오지 못했습니다. 다시 시도해주세요.')),
        );
        return;
      }
    }
    if (_hasSubTasks) {
      setState(() => _expanded = !_expanded);
    } else {
      widget.onTap?.call();
    }
  }

  Future<void> _toggleSubTask(SubTask subTask) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.subTaskRepository!.updateSubTaskDone(
        subTask.id,
        !subTask.isDone,
      );
      if (!mounted) return;
      setState(
        () => _subTasks = [
          for (final item in _subTasks)
            if (item.id == updated.id) updated else item,
        ],
      );
      widget.onSubTasksChanged?.call();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서브 작업을 저장하지 못했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final lists = widget.lists;
    final groups = widget.groups;
    final tags = widget.tags;
    final key = widget.rowKey;
    final leading = widget.leading;
    final onTap = widget.onTap == null
        ? null
        : _canExpand
        ? _handleTap
        : widget.onTap;
    final selectionOnly =
        task.status == TaskStatus.deleted || task.status == TaskStatus.excluded;
    final onLongPress = selectionOnly
        ? widget.onLongPress
        : widget.onLongPress ?? widget.onTap;
    final isExcluded = task.status == TaskStatus.excluded;
    final list = isExcluded
        ? null
        : lists.where((l) => l.id == task.listId).firstOrNull;
    final group = groups.where((g) => g.id == list?.groupId).firstOrNull;
    final path = [
      if (group != null) group.name,
      if (list != null) list.name,
    ].join(' > ');
    final details = [
      if (path.isNotEmpty) path,
      if (isExcluded && path.isEmpty && task.ecampus?.sourceCourse != null)
        task.ecampus!.sourceCourse!,
      for (final tag in tags.where((t) => task.tagIds.contains(t.id)))
        '#${tag.name}',
    ];
    final due = task.dueDate?.toLocal();
    final now = DateTime.now();
    final dueDays = due == null
        ? 0
        : DateTime.utc(
            due.year,
            due.month,
            due.day,
          ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final dueLabel = dueDays == 0
        ? 'D-day'
        : dueDays > 0
        ? 'D-$dueDays'
        : 'D+${-dueDays}';
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppTheme.dangerRed,
      TaskPriority.medium => AppTheme.warningOrange,
      TaskPriority.low => AppTheme.primaryBlue,
      null => null,
    };
    final priorityLabel = switch (task.priority) {
      TaskPriority.high => '우선순위 높음',
      TaskPriority.medium => '우선순위 중간',
      TaskPriority.low => '우선순위 낮음',
      null => null,
    };
    final dueStyle = TextStyle(
      fontSize: 12,
      height: 1.1,
      color:
          task.status == TaskStatus.active &&
              due != null &&
              isDueDateOverdue(due, now: now)
          ? AppTheme.dangerRed
          : AppTheme.muted,
    );
    return Semantics(
      label: priorityLabel,
      expanded: _hasSubTasks ? _expanded : null,
      child: Material(
        color: priorityColor?.withValues(alpha: .08) ?? Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              key: key,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: leading,
              onTap: onTap,
              onLongPress: onLongPress,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 13,
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (_hasSubTasks)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      size: 18,
                      color: AppTheme.muted,
                      semanticLabel: _expanded ? '서브 작업 접기' : '서브 작업 펼치기',
                    ),
                ],
              ),
              subtitle: details.isEmpty
                  ? null
                  : Text(
                      details.join(' · '),
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (due == null)
                    Text('마감 없음', style: dueStyle)
                  else ...[
                    Text(dueLabel, style: dueStyle),
                    Text(
                      DateFormat('HH:mm', 'ko_KR').format(due),
                      style: dueStyle,
                    ),
                  ],
                ],
              ),
            ),
            if (_hasSubTasks && _expanded)
              for (final subTask in _subTasks)
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: ListTile(
                    key: ValueKey<Object>((
                      'subtask',
                      widget.rowKey,
                      subTask.id,
                    )),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    minTileHeight: 48,
                    leading: Checkbox(
                      value: subTask.isDone,
                      semanticLabel: '${subTask.title} 완료',
                      onChanged: _saving
                          ? null
                          : (_) => _toggleSubTask(subTask),
                    ),
                    title: Text(
                      subTask.title,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 13,
                        color: subTask.isDone ? AppTheme.muted : AppTheme.ink,
                        decoration: subTask.isDone
                            ? TextDecoration.lineThrough
                            : null,
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

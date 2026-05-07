import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/sub_task_repository.dart';
import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/sub_task_progress.dart';
import '../debug/ecampus_login_debug_screen.dart';
import '../sync/ecampus_sync_progress_screen.dart';
import '../task/task_detail_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.taskRepository,
    required this.subTaskRepository,
  });

  final TaskRepository taskRepository;
  final SubTaskRepository subTaskRepository;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  var _selectedIndex = 0;
  EcampusSession? _ecampusSession;
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
  }

  Future<List<Task>> _loadTasks() {
    return widget.taskRepository.getTasks(includeArchived: true);
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _loadTasks();
    });
  }

  Future<void> _openEcampusSync() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EcampusSyncProgressScreen(
          taskRepository: widget.taskRepository,
          initialSession: _ecampusSession,
          onSessionChanged: (session) {
            _ecampusSession = session;
          },
        ),
      ),
    );
    if (mounted) {
      _refreshTasks();
    }
  }

  Future<void> _openEcampusDebug() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const EcampusLoginDebugScreen()),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.active
        : TaskStatus.completed;

    await widget.taskRepository.updateTaskStatus(task.id, nextStatus);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(
      context,
      nextStatus == TaskStatus.completed ? '완료 처리했습니다.' : '미완료로 되돌렸습니다.',
    );
  }

  Future<void> _deleteTask(Task task) async {
    await widget.taskRepository.markDeleted(task.id);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '삭제된 작업으로 이동했습니다.');
  }

  Future<void> _restoreTask(Task task) async {
    await widget.taskRepository.restoreTask(task.id);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '작업을 복구했습니다.');
  }

  Future<void> _reorderTasks(List<Task> orderedTasks) async {
    await widget.taskRepository.updateTaskOrder(
      orderedTasks.map((task) => task.id).toList(growable: false),
    );
  }

  Future<void> _openTaskDetail(Task task) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
          taskRepository: widget.taskRepository,
          subTaskRepository: widget.subTaskRepository,
        ),
      ),
    );
    if (mounted) {
      _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const <Task>[];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final pages = [
          _HomePage(
            tasks: tasks,
            isLoading: isLoading,
            onRefresh: _refreshTasks,
            onOpenSync: _openEcampusSync,
            onOpenSettings: () => setState(() => _selectedIndex = 3),
            onToggleTask: _toggleTaskCompletion,
            subTaskRepository: widget.subTaskRepository,
          ),
          _TaskListPage(
            tasks: tasks,
            isLoading: isLoading,
            onRefresh: _refreshTasks,
            onToggleTask: _toggleTaskCompletion,
            onDeleteTask: _deleteTask,
            onRestoreTask: _restoreTask,
            onReorderTasks: _reorderTasks,
            onOpenTaskDetail: _openTaskDetail,
            subTaskRepository: widget.subTaskRepository,
          ),
          _ManagementPage(tasks: tasks),
          _SettingsPage(onOpenSyncDebug: _openEcampusDebug),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_bulleted_rounded),
                selectedIcon: Icon(Icons.format_list_bulleted_rounded),
                label: '목록',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: '관리',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: '설정',
              ),
            ],
          ),
          floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
              ? FloatingActionButton(
                  onPressed: () {
                    _showSnackBar(context, '개인 할 일 추가는 다음 단계에서 연결합니다.');
                  },
                  child: const Icon(Icons.add_rounded),
                )
              : null,
        );
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.tasks,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenSync,
    required this.onOpenSettings,
    required this.onToggleTask,
    required this.subTaskRepository,
  });

  final List<Task> tasks;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSync;
  final VoidCallback onOpenSettings;
  final ValueChanged<Task> onToggleTask;
  final SubTaskRepository subTaskRepository;

  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks
        .where((task) => task.status == TaskStatus.active)
        .toList(growable: false);
    final todayTasks = activeTasks.where(_isDueToday).toList(growable: false);
    final urgentTasks = activeTasks.where(_isUrgent).toList(growable: false);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _todayLabel(DateTime.now()),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                _IconAction(
                  icon: Icons.sync_rounded,
                  color: AppTheme.primaryBlue,
                  onTap: onOpenSync,
                  tooltip: 'e-campus 동기화',
                ),
                const SizedBox(width: 10),
                _IconAction(
                  icon: Icons.settings_rounded,
                  color: AppTheme.ink,
                  onTap: onOpenSettings,
                  tooltip: '설정',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SummaryCard(
              items: [
                _SummaryItem(
                  icon: Icons.event_available_rounded,
                  label: '오늘 할 일',
                  value: '${todayTasks.length}',
                  color: AppTheme.successGreen,
                ),
                _SummaryItem(
                  icon: Icons.schedule_rounded,
                  label: '마감 임박',
                  value: '${urgentTasks.length}',
                  color: AppTheme.warningOrange,
                ),
                _SummaryItem(
                  icon: Icons.assignment_outlined,
                  label: '미완료',
                  value: '${activeTasks.length}',
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: '오늘 할 일', count: todayTasks.length),
            const SizedBox(height: 12),
            if (isLoading)
              const _LoadingBlock()
            else if (todayTasks.isEmpty)
              const _EmptyBlock(message: '오늘 마감인 일정이 없습니다.')
            else
              for (final task in todayTasks.take(3)) ...[
                _TaskCard(
                  task: task,
                  expanded: true,
                  onToggle: () => onToggleTask(task),
                  subTaskRepository: subTaskRepository,
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 20),
            _SectionHeader(title: '마감 임박', count: urgentTasks.length),
            const SizedBox(height: 12),
            if (urgentTasks.isEmpty)
              const _EmptyBlock(message: '가까운 마감 일정이 없습니다.')
            else
              _CompactTaskList(
                tasks: urgentTasks.take(4).toList(),
                onToggleTask: onToggleTask,
                subTaskRepository: subTaskRepository,
              ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: onOpenSync,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('마지막 동기화 확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListPage extends StatefulWidget {
  const _TaskListPage({
    required this.tasks,
    required this.isLoading,
    required this.onRefresh,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onRestoreTask,
    required this.onReorderTasks,
    required this.onOpenTaskDetail,
    required this.subTaskRepository,
  });

  final List<Task> tasks;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onDeleteTask;
  final ValueChanged<Task> onRestoreTask;
  final Future<void> Function(List<Task> orderedTasks) onReorderTasks;
  final ValueChanged<Task> onOpenTaskDetail;
  final SubTaskRepository subTaskRepository;

  @override
  State<_TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<_TaskListPage> {
  var _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = _visibleTasks();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '목록',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: '새로고침',
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _TaskFilter.values) ...[
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.isLoading)
              const _LoadingBlock()
            else if (visibleTasks.isEmpty)
              const _EmptyBlock(message: '표시할 일정이 없습니다.')
            else
              ..._buildTaskSections(visibleTasks),
          ],
        ),
      ),
    );
  }

  List<Task> _visibleTasks() {
    final tasks = widget.tasks.where(_matchesFilter).toList();
    tasks.sort(_compareDueDate);
    return tasks;
  }

  bool _matchesFilter(Task task) {
    return switch (_filter) {
      _TaskFilter.all => !_isHiddenInMainList(task),
      _TaskFilter.ecampus =>
        task.origin == TaskOrigin.ecampus && !_isHiddenInMainList(task),
      _TaskFilter.personal =>
        task.origin == TaskOrigin.personal && !_isHiddenInMainList(task),
      _TaskFilter.incomplete => task.status == TaskStatus.active,
      _TaskFilter.completed => task.status == TaskStatus.completed,
      _TaskFilter.deleted => task.status == TaskStatus.deleted,
    };
  }

  List<Widget> _buildTaskSections(List<Task> tasks) {
    if (_filter == _TaskFilter.deleted) {
      return [
        _DeletedTaskList(tasks: tasks, onRestoreTask: widget.onRestoreTask),
      ];
    }

    if (_filter == _TaskFilter.incomplete || _filter == _TaskFilter.completed) {
      return [
        _TaskSectionCard(
          tasks: tasks,
          onToggleTask: widget.onToggleTask,
          onDeleteTask: widget.onDeleteTask,
          onOpenTaskDetail: widget.onOpenTaskDetail,
          subTaskRepository: widget.subTaskRepository,
          onReorderTasks: widget.onReorderTasks,
        ),
      ];
    }

    final incompleteTasks = tasks
        .where((task) => task.status == TaskStatus.active)
        .toList(growable: false);
    final completedTasks = tasks
        .where((task) => task.status == TaskStatus.completed)
        .toList(growable: false);

    return [
      _ListSectionHeader(title: '미완료', count: incompleteTasks.length),
      const SizedBox(height: 10),
      if (incompleteTasks.isEmpty)
        const _EmptyBlock(message: '해야 할 작업이 없습니다.')
      else
        _TaskSectionCard(
          tasks: incompleteTasks,
          onToggleTask: widget.onToggleTask,
          onDeleteTask: widget.onDeleteTask,
          onOpenTaskDetail: widget.onOpenTaskDetail,
          subTaskRepository: widget.subTaskRepository,
          onReorderTasks: widget.onReorderTasks,
        ),
      const SizedBox(height: 24),
      _ListSectionHeader(title: '완료', count: completedTasks.length),
      const SizedBox(height: 10),
      if (completedTasks.isEmpty)
        const _EmptyBlock(message: '완료된 작업이 없습니다.')
      else
        _TaskSectionCard(
          tasks: completedTasks,
          onToggleTask: widget.onToggleTask,
          onDeleteTask: widget.onDeleteTask,
          onOpenTaskDetail: widget.onOpenTaskDetail,
          subTaskRepository: widget.subTaskRepository,
          onReorderTasks: widget.onReorderTasks,
        ),
    ];
  }
}

bool _isHiddenInMainList(Task task) {
  return task.status == TaskStatus.deleted ||
      task.status == TaskStatus.excluded;
}

class _ManagementPage extends StatelessWidget {
  const _ManagementPage({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final deletedCount = tasks
        .where((task) => task.status == TaskStatus.deleted)
        .length;
    final excludedCount = tasks
        .where((task) => task.status == TaskStatus.excluded)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        children: [
          _PageTitle(title: '관리'),
          const SizedBox(height: 28),
          _ManagementSection(
            title: '태그',
            children: const [
              _ManagementRow(
                icon: Icons.circle,
                iconColor: AppTheme.successGreen,
                title: '전공',
                subtitle: '기본 우선순위 높음',
              ),
              _ManagementRow(
                icon: Icons.circle,
                iconColor: AppTheme.primaryBlue,
                title: '교양',
                subtitle: '기본 우선순위 보통',
              ),
              _ManagementRow(
                icon: Icons.circle,
                iconColor: AppTheme.warningOrange,
                title: '팀플',
                subtitle: '기본 우선순위 높음',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ManagementSection(
            title: '폴더',
            children: const [
              _ManagementRow(
                icon: Icons.folder_rounded,
                iconColor: AppTheme.successGreen,
                title: '이번 주 집중',
              ),
              _ManagementRow(
                icon: Icons.folder_rounded,
                iconColor: AppTheme.successGreen,
                title: '졸업작품',
              ),
              _ManagementRow(
                icon: Icons.folder_rounded,
                iconColor: AppTheme.successGreen,
                title: '시험기간',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ManagementSection(
            title: '정리',
            children: [
              _ManagementRow(
                icon: Icons.delete_outline_rounded,
                iconColor: AppTheme.muted,
                title: '삭제된 작업',
                trailing: '$deletedCount',
              ),
              _ManagementRow(
                icon: Icons.block_rounded,
                iconColor: AppTheme.muted,
                title: '가져오지 않을 e-campus 항목',
                trailing: '$excludedCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.onOpenSyncDebug});

  final VoidCallback onOpenSyncDebug;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        children: [
          _PageTitle(title: '설정'),
          const SizedBox(height: 28),
          _SettingsSection(
            title: 'e-campus 연동',
            children: [
              const _SettingsSwitchRow(
                icon: Icons.lock_outline_rounded,
                title: '로그인 상태 유지',
                value: true,
              ),
              const _SettingsSwitchRow(
                icon: Icons.sync_rounded,
                title: '앱 실행 시 자동 동기화',
                value: false,
              ),
              _SettingsActionRow(
                icon: Icons.sync_rounded,
                title: 'e-campus 연동 테스트',
                subtitle: '로그인, todo, 로그아웃 확인',
                onTap: onOpenSyncDebug,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsSection(
            title: '알림',
            children: [
              _SettingsInfoRow(
                icon: Icons.notifications_rounded,
                title: '기본 알림',
                value: '1일 전 09:00',
              ),
              _SettingsInfoRow(
                icon: Icons.access_time_rounded,
                title: '마감 임박 기준',
                value: '3일 이내',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsSection(
            title: '보안',
            children: [
              _SettingsInfoRow(
                icon: Icons.verified_user_outlined,
                title: '계정 저장 정책',
                value: '저장 안 함',
                subtitle: '비밀번호는 저장하지 않음',
              ),
              _SettingsInfoRow(
                icon: Icons.delete_outline_rounded,
                title: '세션/쿠키 정리',
                value: '로그아웃 시',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 92,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: _SummaryCell(item: items[i])),
              if (i != items.length - 1)
                const SizedBox(
                  height: 56,
                  child: VerticalDivider(width: 1, color: AppTheme.line),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 18, color: item.color),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: TextStyle(
            color: item.color,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.subTaskRepository,
    this.expanded = false,
  });

  final Task task;
  final VoidCallback onToggle;
  final SubTaskRepository subTaskRepository;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCheckbox(task: task, onTap: onToggle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (task.dueDate != null) _DueChip(task: task),
                      _OriginChip(origin: task.origin),
                      if (task.ecampus?.sourceCourse != null)
                        _NeutralChip(label: task.ecampus!.sourceCourse!),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 14),
                    _SubTaskProgressView(
                      taskId: task.id,
                      subTaskRepository: subTaskRepository,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PriorityDot(priority: task.priority),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onOpenDetail,
    required this.subTaskRepository,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpenDetail;
  final SubTaskRepository subTaskRepository;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isCompleted ? 10 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCheckbox(task: task, onTap: onToggle),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: isCompleted ? 2 : null,
                  overflow: isCompleted ? TextOverflow.ellipsis : null,
                  style: TextStyle(
                    color: isCompleted ? AppTheme.muted : AppTheme.ink,
                    fontSize: isCompleted ? 15 : 17,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (task.dueDate != null) _DueChip(task: task),
                      _OriginChip(origin: task.origin),
                      if (task.ecampus?.sourceCourse != null)
                        _NeutralChip(label: task.ecampus!.sourceCourse!),
                    ],
                  ),
                  _SubTaskProgressView(
                    taskId: task.id,
                    subTaskRepository: subTaskRepository,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted) ...[
                  _PriorityDot(priority: task.priority),
                  const SizedBox(width: 4),
                ],
                SizedBox.square(
                  dimension: 32,
                  child: _TaskEditButton(onTap: onOpenDetail),
                ),
                SizedBox.square(
                  dimension: 32,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppTheme.muted,
                    tooltip: '삭제',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSectionCard extends StatefulWidget {
  const _TaskSectionCard({
    required this.tasks,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onOpenTaskDetail,
    required this.subTaskRepository,
    required this.onReorderTasks,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onDeleteTask;
  final ValueChanged<Task> onOpenTaskDetail;
  final SubTaskRepository subTaskRepository;
  final Future<void> Function(List<Task> orderedTasks) onReorderTasks;

  @override
  State<_TaskSectionCard> createState() => _TaskSectionCardState();
}

class _TaskSectionCardState extends State<_TaskSectionCard> {
  late List<Task> _orderedTasks;

  @override
  void initState() {
    super.initState();
    _orderedTasks = List<Task>.of(widget.tasks);
  }

  @override
  void didUpdateWidget(_TaskSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousIds = _orderedTasks.map((task) => task.id).join('|');
    final nextIds = widget.tasks.map((task) => task.id).join('|');

    if (previousIds != nextIds) {
      _orderedTasks = List<Task>.of(widget.tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _orderedTasks.length,
        onReorder: (oldIndex, newIndex) async {
          final previousTasks = List<Task>.of(_orderedTasks);
          final reorderedTasks = List<Task>.of(_orderedTasks);
          final adjustedNewIndex = newIndex > oldIndex
              ? newIndex - 1
              : newIndex;
          final movedTask = reorderedTasks.removeAt(oldIndex);
          reorderedTasks.insert(adjustedNewIndex, movedTask);

          setState(() {
            _orderedTasks = reorderedTasks;
          });

          try {
            await widget.onReorderTasks(reorderedTasks);
          } catch (_) {
            if (!context.mounted) {
              return;
            }
            setState(() {
              _orderedTasks = previousTasks;
            });
            _showSnackBar(context, '순서 저장에 실패했습니다.');
          }
        },
        itemBuilder: (context, index) {
          final task = _orderedTasks[index];
          return Column(
            key: ValueKey(task.id),
            children: [
              ReorderableDelayedDragStartListener(
                index: index,
                child: _TaskListTile(
                  task: task,
                  onToggle: () => widget.onToggleTask(task),
                  onDelete: () => widget.onDeleteTask(task),
                  onOpenDetail: () => widget.onOpenTaskDetail(task),
                  subTaskRepository: widget.subTaskRepository,
                ),
              ),
              if (index != _orderedTasks.length - 1)
                const Divider(height: 1, indent: 64),
            ],
          );
        },
      ),
    );
  }
}

class _DeletedTaskList extends StatelessWidget {
  const _DeletedTaskList({required this.tasks, required this.onRestoreTask});

  final List<Task> tasks;
  final ValueChanged<Task> onRestoreTask;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            _DeletedTaskTile(
              task: tasks[i],
              onRestore: () => onRestoreTask(tasks[i]),
            ),
            if (i != tasks.length - 1) const Divider(height: 1, indent: 16),
          ],
        ],
      ),
    );
  }
}

class _DeletedTaskTile extends StatelessWidget {
  const _DeletedTaskTile({required this.task, required this.onRestore});

  final Task task;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        task.ecampus?.sourceCourse ??
            (task.origin == TaskOrigin.ecampus ? 'e-campus' : '개인'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: TextButton.icon(
        onPressed: onRestore,
        icon: const Icon(Icons.restore_rounded, size: 18),
        label: const Text('복구'),
      ),
    );
  }
}

class _CompactTaskList extends StatelessWidget {
  const _CompactTaskList({
    required this.tasks,
    required this.onToggleTask,
    required this.subTaskRepository,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onToggleTask;
  final SubTaskRepository subTaskRepository;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _StatusCheckbox(
                    task: tasks[i],
                    onTap: () => onToggleTask(tasks[i]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tasks[i].title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (tasks[i].dueDate != null) _DueChip(task: tasks[i]),
                ],
              ),
            ),
            _CompactProgressPadding(
              taskId: tasks[i].id,
              subTaskRepository: subTaskRepository,
            ),
            if (i != tasks.length - 1) const Divider(height: 1, indent: 54),
          ],
        ],
      ),
    );
  }
}

class _TaskEditButton extends StatelessWidget {
  const _TaskEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.more_vert_rounded),
      color: AppTheme.muted,
      tooltip: '작업 상세/수정',
      padding: EdgeInsets.zero,
      iconSize: 20,
    );
  }
}

class _StatusCheckbox extends StatelessWidget {
  const _StatusCheckbox({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final checked = task.status == TaskStatus.completed;
    final disabled =
        task.status == TaskStatus.deleted || task.status == TaskStatus.excluded;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: checked ? AppTheme.successGreen : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: disabled
                ? AppTheme.line
                : checked
                ? AppTheme.successGreen
                : AppTheme.muted,
            width: 1.6,
          ),
        ),
        child: checked
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate;
    if (dueDate == null) {
      return const SizedBox.shrink();
    }

    return _ColoredChip(
      label: _dueLabel(dueDate),
      color: _isOverdue(dueDate)
          ? AppTheme.dangerRed
          : _isDueToday(task)
          ? AppTheme.successGreen
          : AppTheme.warningOrange,
    );
  }
}

class _OriginChip extends StatelessWidget {
  const _OriginChip({required this.origin});

  final TaskOrigin origin;

  @override
  Widget build(BuildContext context) {
    final isEcampus = origin == TaskOrigin.ecampus;
    return _ColoredChip(
      label: isEcampus ? 'e-campus' : '개인',
      color: isEcampus ? AppTheme.primaryBlue : AppTheme.ink,
    );
  }
}

class _ColoredChip extends StatelessWidget {
  const _ColoredChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NeutralChip extends StatelessWidget {
  const _NeutralChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SubTaskProgressView extends StatelessWidget {
  const _SubTaskProgressView({
    required this.taskId,
    required this.subTaskRepository,
  });

  final String taskId;
  final SubTaskRepository subTaskRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SubTask>>(
      future: subTaskRepository.getSubTasks(taskId),
      builder: (context, snapshot) {
        final progress = calculateSubTaskProgress(
          snapshot.data ?? const <SubTask>[],
        );
        if (!progress.hasSubTasks) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '서브 작업 ${progress.doneCount}/${progress.totalCount} 완료',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${progress.percent}%',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 5,
                  backgroundColor: AppTheme.line,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.successGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactProgressPadding extends StatelessWidget {
  const _CompactProgressPadding({
    required this.taskId,
    required this.subTaskRepository,
  });

  final String taskId;
  final SubTaskRepository subTaskRepository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(54, 0, 14, 12),
      child: _SubTaskProgressView(
        taskId: taskId,
        subTaskRepository: subTaskRepository,
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final TaskPriority? priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high => AppTheme.dangerRed,
      TaskPriority.medium => AppTheme.warningOrange,
      TaskPriority.low => AppTheme.successGreen,
      null => AppTheme.primaryBlue,
    };

    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          _ColoredChip(label: '$count', color: AppTheme.successGreen),
      ],
    );
  }
}

class _ListSectionHeader extends StatelessWidget {
  const _ListSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        _ColoredChip(label: '$count', color: AppTheme.successGreen),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.line),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message, style: const TextStyle(color: AppTheme.muted)),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, indent: 58),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagementRow extends StatelessWidget {
  const _ManagementRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing == null
          ? const Icon(Icons.chevron_right_rounded)
          : Text(
              trailing!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.muted,
              ),
            ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, indent: 58),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 28,
      leading: _SettingsIcon(icon: icon, color: AppTheme.successGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Switch(value: value, onChanged: (_) {}),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 28,
      leading: _SettingsIcon(icon: icon, color: AppTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 86),
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minLeadingWidth: 28,
      leading: _SettingsIcon(icon: icon, color: AppTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

enum _TaskFilter {
  all('전체'),
  ecampus('e-campus'),
  personal('개인'),
  incomplete('미완료'),
  completed('완료'),
  deleted('삭제됨');

  const _TaskFilter(this.label);

  final String label;
}

bool _isDueToday(Task task) {
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return false;
  }
  final now = DateTime.now();
  return dueDate.year == now.year &&
      dueDate.month == now.month &&
      dueDate.day == now.day;
}

bool _isUrgent(Task task) {
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return false;
  }
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final days = dueDay.difference(startOfToday).inDays;
  return days >= 0 && days <= 3 && !_isDueToday(task);
}

bool _isOverdue(DateTime dueDate) {
  return dueDate.isBefore(DateTime.now());
}

int _compareDueDate(Task a, Task b) {
  final aDueDate = a.dueDate;
  final bDueDate = b.dueDate;
  if (aDueDate == null && bDueDate == null) {
    return a.createdAt.compareTo(b.createdAt);
  }
  if (aDueDate == null) {
    return 1;
  }
  if (bDueDate == null) {
    return -1;
  }
  return aDueDate.compareTo(bDueDate);
}

String _todayLabel(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
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

String _dueLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(date.year, date.month, date.day);
  final days = dueDay.difference(today).inDays;
  final time =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  if (days == 0) {
    return date.hour == 0 && date.minute == 0 ? '오늘' : '오늘 $time';
  }
  if (days == 1) {
    return date.hour == 0 && date.minute == 0 ? '내일' : '내일 $time';
  }
  return '${date.month}월 ${date.day}일';
}

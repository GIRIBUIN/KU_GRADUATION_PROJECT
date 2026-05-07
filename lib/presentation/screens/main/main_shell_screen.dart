import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/repositories/task_repository.dart';
import '../debug/ecampus_login_debug_screen.dart';
import '../sync/ecampus_sync_progress_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.taskRepository});

  final TaskRepository taskRepository;

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
          ),
          _TaskListPage(
            tasks: tasks,
            isLoading: isLoading,
            onRefresh: _refreshTasks,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('개인 할 일 추가는 다음 단계에서 연결합니다.'),
                      ),
                    );
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
  });

  final List<Task> tasks;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSync;
  final VoidCallback onOpenSettings;

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
                _TaskCard(task: task, expanded: true),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 20),
            _SectionHeader(title: '마감 임박', count: urgentTasks.length),
            const SizedBox(height: 12),
            if (urgentTasks.isEmpty)
              const _EmptyBlock(message: '가까운 마감 일정이 없습니다.')
            else
              _CompactTaskList(tasks: urgentTasks.take(4).toList()),
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
  });

  final List<Task> tasks;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  State<_TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<_TaskListPage> {
  var _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final filteredTasks = widget.tasks.where(_matchesFilter).toList()
      ..sort(_compareDueDate);

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
            TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: '작업 검색',
                prefixIcon: const Icon(Icons.search_rounded),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
              ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  '마감일순',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.swap_vert_rounded, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.isLoading)
              const _LoadingBlock()
            else if (filteredTasks.isEmpty)
              const _EmptyBlock(message: '표시할 일정이 없습니다.')
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < filteredTasks.length; i++) ...[
                      _TaskListTile(task: filteredTasks[i]),
                      if (i != filteredTasks.length - 1)
                        const Divider(height: 1, indent: 64),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(Task task) {
    return switch (_filter) {
      _TaskFilter.all => true,
      _TaskFilter.ecampus => task.origin == TaskOrigin.ecampus,
      _TaskFilter.personal => task.origin == TaskOrigin.personal,
      _TaskFilter.incomplete => task.status == TaskStatus.active,
      _TaskFilter.completed => task.status == TaskStatus.completed,
      _TaskFilter.deleted => task.status == TaskStatus.deleted,
    };
  }
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
  const _TaskCard({required this.task, this.expanded = false});

  final Task task;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCheckbox(task: task),
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
                    Text(
                      task.memo?.isNotEmpty == true
                          ? task.memo!
                          : '서브 작업은 다음 단계에서 연결합니다.',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
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
  const _TaskListTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCheckbox(task: task),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PriorityDot(priority: task.priority),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _CompactTaskList extends StatelessWidget {
  const _CompactTaskList({required this.tasks});

  final List<Task> tasks;

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
                  _StatusCheckbox(task: tasks[i]),
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
            if (i != tasks.length - 1) const Divider(height: 1, indent: 54),
          ],
        ],
      ),
    );
  }
}

class _StatusCheckbox extends StatelessWidget {
  const _StatusCheckbox({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final checked = task.status == TaskStatus.completed;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: checked ? AppTheme.successGreen : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppTheme.successGreen : AppTheme.muted,
          width: 1.6,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
          : null,
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
      trailing: Switch(
        value: value,
        onChanged: (_) {},
      ),
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

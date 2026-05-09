import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/sub_task_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/default_ecampus_sync_service.dart';
import '../../../data/services/default_ecampus_todo_service.dart';
import '../../../data/services/ecampus_sync_apply_service.dart';
import '../../../data/services/ecampus_sync_classifier.dart';
import '../../../data/services/ecampus_sync_flow_service.dart';
import '../../../data/services/ecampus_todo_parser.dart';
import '../../../data/services/http_ecampus_auth_service.dart';
import '../../../data/services/http_ecampus_todo_client.dart';
import '../../../data/services/sub_task_progress.dart';
import '../../services/in_app_webview_ecampus_cookie_store.dart';
import '../../services/local_notification_service.dart';
import '../login/ecampus_login_webview_screen.dart';
import '../sync/ecampus_sync_preview_screen.dart';
import '../task/task_create_screen.dart';
import '../task/task_detail_screen.dart';
import '../../widgets/task_metadata_picker.dart' as metadata_picker;

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
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
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  var _selectedIndex = 0;
  EcampusSession? _ecampusSession;
  Timer? _clockRefreshTimer;
  late Future<List<Task>> _tasksFuture;
  late Future<AppSettings> _settingsFuture;
  late Future<_TaskMetadataLookup> _metadataFuture;
  var _metadataVersion = 0;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
    _settingsFuture = widget.settingsRepository.getSettings();
    _metadataFuture = _loadMetadata();
    _clockRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clockRefreshTimer?.cancel();
    super.dispose();
  }

  Future<List<Task>> _loadTasks() {
    return widget.taskRepository.getTasks(includeArchived: true);
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _loadTasks();
    });
  }

  Future<_TaskMetadataLookup> _loadMetadata() async {
    final tags = await widget.tagRepository.getTags();
    final folders = await widget.folderRepository.getFolders();
    return _TaskMetadataLookup(tags: tags, folders: folders);
  }

  void _refreshMetadata() {
    setState(() {
      _metadataFuture = _loadMetadata();
      _metadataVersion++;
    });
  }

  void _refreshTasksAndMetadata() {
    setState(() {
      _tasksFuture = _loadTasks();
      _metadataFuture = _loadMetadata();
      _metadataVersion++;
    });
  }

  Future<void> _openEcampusSync() async {
    var session = _ecampusSession;
    session ??= await Navigator.of(context).push<EcampusSession>(
      MaterialPageRoute(
        builder: (_) => const EcampusLoginWebViewScreen(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || session == null) {
      return;
    }

    _ecampusSession = session;

    final httpClient = http.Client();
    final syncFlowService = _buildEcampusSyncFlowService(httpClient);
    var loadingDialogOpen = false;

    try {
      loadingDialogOpen = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _SyncLoadingDialog(),
        ).then((_) {
          loadingDialogOpen = false;
        }),
      );

      final result = await syncFlowService.preview(session: session);

      if (!mounted) {
        return;
      }
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogOpen = false;
      }

      final didImport = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EcampusSyncPreviewScreen(
            syncResult: result,
            syncFlowService: syncFlowService,
          ),
        ),
      );

      if (!mounted) {
        return;
      }
      if (didImport == true) {
        _refreshTasksAndMetadata();
      } else {
        _refreshTasks();
      }
    } on EcampusSessionExpiredException catch (_) {
      _ecampusSession = null;
      if (!mounted) {
        return;
      }
      _showSnackBar(context, '로그인 세션이 만료되었습니다. 다시 로그인해주세요.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context, '동기화에 실패했습니다: $error');
    } finally {
      if (mounted && loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      httpClient.close();
    }
  }

  EcampusSyncFlowService _buildEcampusSyncFlowService(http.Client httpClient) {
    final todoService = DefaultEcampusTodoService(
      client: HttpEcampusTodoClient(httpClient: httpClient),
      parser: const EcampusTodoParser(),
    );
    return DefaultEcampusSyncFlowService(
      taskRepository: widget.taskRepository,
      syncService: DefaultEcampusSyncService(
        todoService: todoService,
        classifier: const EcampusSyncClassifier(),
      ),
      applyService: DefaultEcampusSyncApplyService(
        taskRepository: widget.taskRepository,
      ),
    );
  }

  Future<void> _clearEcampusSession() async {
    final httpClient = http.Client();
    final cookieStore = const InAppWebViewEcampusCookieStore();
    final authService = HttpEcampusAuthService(
      httpClient: httpClient,
      cookieStore: cookieStore,
    );

    try {
      final session = _ecampusSession;
      if (session == null) {
        await authService.clearSession();
      } else {
        await authService.logout(session);
      }
    } finally {
      httpClient.close();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _ecampusSession = null;
    });
    _showSnackBar(context, 'e-campus 세션과 쿠키를 정리했습니다.');
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.active
        : TaskStatus.completed;

    final updatedTask = await widget.taskRepository.updateTaskStatus(
      task.id,
      nextStatus,
    );
    if (!mounted) {
      return;
    }

    if (nextStatus == TaskStatus.active) {
      await _scheduleTaskNotification(updatedTask);
    } else {
      await _cancelTaskNotification(task.id);
    }
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
    await _cancelTaskNotification(task.id);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '삭제된 작업으로 이동했습니다.');
  }

  Future<void> _deleteCompletedTasks(List<Task> tasks) async {
    for (final task in tasks) {
      await widget.taskRepository.markDeleted(task.id);
      await _cancelTaskNotification(task.id);
    }
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '완료된 작업을 삭제된 작업으로 이동했습니다.');
  }

  Future<void> _restoreTask(Task task) async {
    final restoredTask = await widget.taskRepository.restoreTask(task.id);
    if (!mounted) {
      return;
    }

    await _scheduleTaskNotification(restoredTask);
    if (!mounted) {
      return;
    }
    _refreshTasks();
    _showSnackBar(context, '작업을 복구했습니다.');
  }

  Future<void> _deleteTaskPermanently(Task task) async {
    await widget.taskRepository.deletePermanently(task.id);
    await _cancelTaskNotification(task.id);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '작업을 영구 삭제했습니다.');
  }

  Future<void> _reorderTasks(List<Task> orderedTasks) async {
    await widget.taskRepository.updateTaskOrder(
      orderedTasks.map((task) => task.id).toList(growable: false),
    );
  }

  Future<void> _scheduleTaskNotification(Task task) async {
    final setting = await widget.notificationRepository.getByTaskId(task.id);
    if (setting == null) {
      await _cancelTaskNotification(task.id);
      return;
    }

    await widget.localNotificationService.scheduleTaskNotification(
      task: task,
      setting: setting,
    );
  }

  Future<void> _cancelTaskNotification(String taskId) {
    return widget.localNotificationService.cancelTaskNotification(taskId);
  }

  Future<void> _openTaskDetail(Task task) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
          taskRepository: widget.taskRepository,
          subTaskRepository: widget.subTaskRepository,
          notificationRepository: widget.notificationRepository,
          tagRepository: widget.tagRepository,
          folderRepository: widget.folderRepository,
          localNotificationService: widget.localNotificationService,
        ),
      ),
    );
    if (mounted) {
      _refreshTasksAndMetadata();
    }
  }

  Future<void> _openTaskCreate() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskCreateScreen(
          taskRepository: widget.taskRepository,
          subTaskRepository: widget.subTaskRepository,
          notificationRepository: widget.notificationRepository,
          settingsRepository: widget.settingsRepository,
          tagRepository: widget.tagRepository,
          folderRepository: widget.folderRepository,
          localNotificationService: widget.localNotificationService,
        ),
      ),
    );
    if (mounted) {
      _refreshTasksAndMetadata();
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
        return FutureBuilder<AppSettings>(
          future: _settingsFuture,
          builder: (context, settingsSnapshot) {
            final settings =
                settingsSnapshot.data ??
                const AppSettings(
                  autoSyncEnabled: false,
                  saveEcampusAccount: false,
                  defaultNotificationEnabled: true,
                  defaultNotificationDays: 60,
                  defaultNotificationTime: 'relative',
                  urgentDueDays: 3,
                );
            return FutureBuilder<_TaskMetadataLookup>(
              future: _metadataFuture,
              builder: (context, metadataSnapshot) {
                final metadata =
                    metadataSnapshot.data ?? const _TaskMetadataLookup.empty();
                final pages = [
                  _HomePage(
                    tasks: tasks,
                    isLoading: isLoading,
                    urgentDueDays: settings.urgentDueDays,
                    metadata: metadata,
                    onRefresh: _refreshTasks,
                    onOpenSync: _openEcampusSync,
                    onOpenSettings: () => setState(() => _selectedIndex = 3),
                    onToggleTask: _toggleTaskCompletion,
                    onDeleteTask: _deleteTask,
                    onReorderTasks: _reorderTasks,
                    onOpenTaskDetail: _openTaskDetail,
                    subTaskRepository: widget.subTaskRepository,
                  ),
                  _TaskListPage(
                    tasks: tasks,
                    isLoading: isLoading,
                    metadata: metadata,
                    onRefresh: _refreshTasks,
                    onToggleTask: _toggleTaskCompletion,
                    onDeleteTask: _deleteTask,
                    onDeleteCompletedTasks: _deleteCompletedTasks,
                    onRestoreTask: _restoreTask,
                    onReorderTasks: _reorderTasks,
                    onOpenTaskDetail: _openTaskDetail,
                    subTaskRepository: widget.subTaskRepository,
                  ),
                  _ManagementPage(
                    tasks: tasks,
                    tagRepository: widget.tagRepository,
                    folderRepository: widget.folderRepository,
                    metadataVersion: _metadataVersion,
                    onMetadataChanged: _refreshMetadata,
                    onOpenTaskDetail: _openTaskDetail,
                    onRestoreTask: _restoreTask,
                    onDeletePermanently: _deleteTaskPermanently,
                  ),
                  _SettingsPage(
                    settingsRepository: widget.settingsRepository,
                    isEcampusLoggedIn:
                        _ecampusSession?.hasSessionCookie == true,
                    onSettingsChanged: () {
                      setState(() {
                        _settingsFuture = widget.settingsRepository
                            .getSettings();
                      });
                    },
                    onOpenSync: _openEcampusSync,
                    onClearEcampusSession: _clearEcampusSession,
                    localNotificationService: widget.localNotificationService,
                  ),
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
                  floatingActionButton:
                      _selectedIndex == 0 || _selectedIndex == 1
                      ? FloatingActionButton(
                          onPressed: _openTaskCreate,
                          child: const Icon(Icons.add_rounded),
                        )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.tasks,
    required this.isLoading,
    required this.urgentDueDays,
    required this.metadata,
    required this.onRefresh,
    required this.onOpenSync,
    required this.onOpenSettings,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onReorderTasks,
    required this.onOpenTaskDetail,
    required this.subTaskRepository,
  });

  final List<Task> tasks;
  final bool isLoading;
  final int urgentDueDays;
  final _TaskMetadataLookup metadata;
  final VoidCallback onRefresh;
  final Future<void> Function() onOpenSync;
  final VoidCallback onOpenSettings;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onDeleteTask;
  final Future<void> Function(List<Task> orderedTasks) onReorderTasks;
  final ValueChanged<Task> onOpenTaskDetail;
  final SubTaskRepository subTaskRepository;

  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks
        .where((task) => task.status == TaskStatus.active)
        .toList(growable: false);
    final todayTasks = activeTasks.where(_isDueToday).toList(growable: false);
    final urgentTasks = activeTasks
        .where((task) => _isUrgent(task, urgentDueDays))
        .toList(growable: false);

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
              _TaskSectionCard(
                tasks: todayTasks.take(3).toList(growable: false),
                onToggleTask: onToggleTask,
                onDeleteTask: onDeleteTask,
                onOpenTaskDetail: onOpenTaskDetail,
                subTaskRepository: subTaskRepository,
                onReorderTasks: onReorderTasks,
                enableReorder: true,
                metadata: metadata,
              ),
            const SizedBox(height: 20),
            _SectionHeader(title: '마감 임박', count: urgentTasks.length),
            const SizedBox(height: 12),
            if (urgentTasks.isEmpty)
              const _EmptyBlock(message: '가까운 마감 일정이 없습니다.')
            else
              _TaskSectionCard(
                tasks: urgentTasks.take(4).toList(growable: false),
                onToggleTask: onToggleTask,
                onDeleteTask: onDeleteTask,
                onOpenTaskDetail: onOpenTaskDetail,
                subTaskRepository: subTaskRepository,
                onReorderTasks: onReorderTasks,
                enableReorder: true,
                metadata: metadata,
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
    required this.metadata,
    required this.onRefresh,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onDeleteCompletedTasks,
    required this.onRestoreTask,
    required this.onReorderTasks,
    required this.onOpenTaskDetail,
    required this.subTaskRepository,
  });

  final List<Task> tasks;
  final bool isLoading;
  final _TaskMetadataLookup metadata;
  final VoidCallback onRefresh;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onDeleteTask;
  final Future<void> Function(List<Task> tasks) onDeleteCompletedTasks;
  final ValueChanged<Task> onRestoreTask;
  final Future<void> Function(List<Task> orderedTasks) onReorderTasks;
  final ValueChanged<Task> onOpenTaskDetail;
  final SubTaskRepository subTaskRepository;

  @override
  State<_TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<_TaskListPage> {
  var _filter = _TaskFilter.all;
  var _sort = _TaskSort.userOrder;
  final Map<String, int> _localSortOrders = {};

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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SortSelector(
                  value: _sort,
                  onChanged: (sort) {
                    setState(() {
                      _sort = sort;
                    });
                  },
                ),
                _FilterSelector(
                  value: _filter,
                  onChanged: (filter) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.isLoading)
              const _LoadingBlock()
            else if (visibleTasks.isEmpty)
              _EmptyBlock(message: _emptyMessage())
            else
              ..._buildTaskSections(visibleTasks),
          ],
        ),
      ),
    );
  }

  List<Task> _visibleTasks() {
    final tasks = widget.tasks
        .map(_taskWithLocalSortOrder)
        .where(_matchesFilter)
        .toList();
    tasks.sort(_compareTasksBySort(_sort));
    return tasks;
  }

  Task _taskWithLocalSortOrder(Task task) {
    final sortOrder = _localSortOrders[task.id];
    if (sortOrder == null || sortOrder == task.sortOrder) {
      return task;
    }
    return _copyTaskWithSortOrder(task, sortOrder);
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
      _TaskFilter.overdue =>
        task.status == TaskStatus.active &&
            task.dueDate != null &&
            _isOverdue(task.dueDate!),
      _TaskFilter.deleted => task.status == TaskStatus.deleted,
    };
  }

  String _emptyMessage() {
    return switch (_filter) {
      _TaskFilter.overdue => '마감이 지난 작업이 없습니다.',
      _TaskFilter.deleted => '삭제된 작업이 없습니다.',
      _TaskFilter.completed => '완료된 작업이 없습니다.',
      _TaskFilter.incomplete => '해야 할 작업이 없습니다.',
      _TaskFilter.ecampus => 'e-campus 작업이 없습니다.',
      _TaskFilter.personal => '개인 작업이 없습니다.',
      _TaskFilter.all => '표시할 일정이 없습니다.',
    };
  }

  Future<void> _handleReorderTasks(List<Task> orderedTasks) async {
    final reorderedTasks = _tasksWithSequentialSortOrder(orderedTasks);
    setState(() {
      for (final task in reorderedTasks) {
        _localSortOrders[task.id] = task.sortOrder;
      }
    });

    await widget.onReorderTasks(reorderedTasks);
  }

  Future<void> _confirmDeleteCompletedTasks(List<Task> tasks) async {
    if (tasks.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('완료 작업 전체 삭제'),
        content: Text('완료된 작업 ${tasks.length}개를 삭제된 작업으로 이동할까요?'),
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
    if (shouldDelete == true && mounted) {
      await widget.onDeleteCompletedTasks(tasks);
    }
  }

  List<Widget> _buildTaskSections(List<Task> tasks) {
    if (_filter == _TaskFilter.deleted) {
      return [
        _DeletedTaskList(tasks: tasks, onRestoreTask: widget.onRestoreTask),
      ];
    }

    if (_filter == _TaskFilter.incomplete ||
        _filter == _TaskFilter.completed ||
        _filter == _TaskFilter.overdue) {
      return [
        if (_filter == _TaskFilter.completed) ...[
          _CompletedBulkDeleteButton(
            count: tasks.length,
            onPressed: () => _confirmDeleteCompletedTasks(tasks),
          ),
          const SizedBox(height: 10),
        ],
        _TaskSectionCard(
          tasks: tasks,
          onToggleTask: widget.onToggleTask,
          onDeleteTask: widget.onDeleteTask,
          onOpenTaskDetail: widget.onOpenTaskDetail,
          subTaskRepository: widget.subTaskRepository,
          onReorderTasks: _handleReorderTasks,
          enableReorder: _sort == _TaskSort.userOrder,
          metadata: widget.metadata,
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
          onReorderTasks: _handleReorderTasks,
          enableReorder: _sort == _TaskSort.userOrder,
          metadata: widget.metadata,
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
          onReorderTasks: _handleReorderTasks,
          enableReorder: _sort == _TaskSort.userOrder,
          metadata: widget.metadata,
        ),
    ];
  }
}

bool _isHiddenInMainList(Task task) {
  return task.status == TaskStatus.deleted ||
      task.status == TaskStatus.excluded;
}

class _TaskMetadataLookup {
  const _TaskMetadataLookup({
    required List<Tag> tags,
    required List<Folder> folders,
  }) : _tags = tags,
       _folders = folders;

  const _TaskMetadataLookup.empty() : _tags = const [], _folders = const [];

  final List<Tag> _tags;
  final List<Folder> _folders;

  List<Tag> tagsFor(Task task) {
    final ids = task.tagIds.toSet();
    return _tags.where((tag) => ids.contains(tag.id)).toList(growable: false);
  }

  List<Folder> foldersFor(Task task) {
    final ids = task.folderIds.toSet();
    return _folders
        .where((folder) => ids.contains(folder.id))
        .toList(growable: false);
  }
}

class _ManagementPage extends StatefulWidget {
  const _ManagementPage({
    required this.tasks,
    required this.tagRepository,
    required this.folderRepository,
    required this.metadataVersion,
    required this.onMetadataChanged,
    required this.onOpenTaskDetail,
    required this.onRestoreTask,
    required this.onDeletePermanently,
  });

  final List<Task> tasks;
  final TagRepository tagRepository;
  final FolderRepository folderRepository;
  final int metadataVersion;
  final VoidCallback onMetadataChanged;
  final Future<void> Function(Task task) onOpenTaskDetail;
  final Future<void> Function(Task task) onRestoreTask;
  final Future<void> Function(Task task) onDeletePermanently;

  @override
  State<_ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<_ManagementPage> {
  late Future<List<Tag>> _tagsFuture;
  late Future<List<Folder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _tagsFuture = widget.tagRepository.getTags();
    _foldersFuture = widget.folderRepository.getFolders();
  }

  @override
  void didUpdateWidget(covariant _ManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadataVersion != widget.metadataVersion) {
      _reloadMetadataOnly();
    }
  }

  void _reloadMetadataOnly() {
    setState(() {
      _tagsFuture = widget.tagRepository.getTags();
      _foldersFuture = widget.folderRepository.getFolders();
    });
  }

  void _refreshMetadata() {
    _reloadMetadataOnly();
    widget.onMetadataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final deletedCount = widget.tasks
        .where((task) => task.status == TaskStatus.deleted)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        children: [
          _PageTitle(title: '관리'),
          const SizedBox(height: 28),
          FutureBuilder<List<Tag>>(
            future: _tagsFuture,
            builder: (context, snapshot) {
              final tags = snapshot.data ?? const <Tag>[];
              return _ManagementSection(
                title: '태그',
                action: IconButton.filledTonal(
                  onPressed: _createTag,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '태그 추가',
                ),
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData)
                    const _ManagementLoadingRow()
                  else if (tags.isEmpty)
                    const _ManagementEmptyRow(message: '태그가 없습니다.')
                  else
                    for (final tag in tags)
                      _ManagementRow(
                        icon: Icons.circle,
                        iconColor: _colorFromHex(tag.color),
                        title: tag.name,
                        subtitle: '연결된 작업 ${_metadataTaskCountForTag(tag.id)}개',
                        onTap: () => _openTagTasks(tag),
                        onEdit: () => _editTag(tag),
                        editTooltip: '태그 편집',
                      ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Folder>>(
            future: _foldersFuture,
            builder: (context, snapshot) {
              final folders = snapshot.data ?? const <Folder>[];
              final rootFolders = _rootFoldersOf(folders);
              return _ManagementSection(
                title: '폴더',
                action: IconButton.filledTonal(
                  onPressed: () => _createFolder(folders),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '폴더 추가',
                ),
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData)
                    const _ManagementLoadingRow()
                  else if (rootFolders.isEmpty)
                    const _ManagementEmptyRow(message: '폴더가 없습니다.')
                  else
                    for (final folder in rootFolders)
                      _ManagementRow(
                        icon: Icons.folder_rounded,
                        iconColor: _colorFromHex(
                          folder.color,
                          fallback: AppTheme.successGreen,
                        ),
                        title: folder.name,
                        subtitle:
                            '${_folderSubtitle(folder, folders)} · 연결된 작업 ${_metadataTaskCountForFolder(folder.id)}개',
                        onTap: () => _openFolderTasks(folder, folders),
                        onEdit: () => _editFolder(folder, folders),
                        editTooltip: '폴더 편집',
                      ),
                ],
              );
            },
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
                onTap: _openDeletedTasks,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openTagTasks(Tag tag) async {
    final tasks = widget.tasks
        .where(
          (task) => !_isHiddenInMainList(task) && task.tagIds.contains(tag.id),
        )
        .toList(growable: false);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _MetadataTaskListScreen(
          title: tag.name,
          subtitle: '태그 작업',
          icon: Icons.circle,
          iconColor: _colorFromHex(tag.color),
          tasks: tasks,
          onOpenTaskDetail: widget.onOpenTaskDetail,
        ),
      ),
    );
  }

  Future<void> _openDeletedTasks() async {
    final deletedTasks = widget.tasks
        .where((task) => task.status == TaskStatus.deleted)
        .toList(growable: false);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _DeletedTasksManagementScreen(
          tasks: deletedTasks,
          onRestoreTask: widget.onRestoreTask,
          onDeletePermanently: widget.onDeletePermanently,
        ),
      ),
    );
  }

  Future<void> _openFolderTasks(Folder folder, List<Folder> folders) async {
    final tasks = widget.tasks
        .where(
          (task) =>
              !_isHiddenInMainList(task) && task.folderIds.contains(folder.id),
        )
        .toList(growable: false);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _MetadataTaskListScreen(
          title: folder.name,
          subtitle: '폴더 작업',
          icon: Icons.folder_rounded,
          iconColor: _colorFromHex(
            folder.color,
            fallback: AppTheme.successGreen,
          ),
          tasks: tasks,
          childFolders: _childFoldersOf(folder, folders),
          onOpenFolder: (childFolder) => _openFolderTasks(childFolder, folders),
          onEdit: () => _editFolder(folder, folders),
          editTooltip: '현재 폴더 편집',
          onOpenTaskDetail: widget.onOpenTaskDetail,
        ),
      ),
    );
  }

  List<Folder> _childFoldersOf(Folder parent, List<Folder> folders) {
    final children = folders
        .where((folder) => folder.parentFolderId == parent.id)
        .toList(growable: false);
    children.sort((a, b) => a.name.compareTo(b.name));
    return children;
  }

  List<Folder> _rootFoldersOf(List<Folder> folders) {
    final roots = folders
        .where((folder) => folder.parentFolderId == null)
        .toList(growable: false);
    roots.sort((a, b) => a.name.compareTo(b.name));
    return roots;
  }

  int _metadataTaskCountForTag(String tagId) {
    return widget.tasks
        .where(
          (task) => !_isHiddenInMainList(task) && task.tagIds.contains(tagId),
        )
        .length;
  }

  int _metadataTaskCountForFolder(String folderId) {
    return widget.tasks
        .where(
          (task) =>
              !_isHiddenInMainList(task) && task.folderIds.contains(folderId),
        )
        .length;
  }

  Future<void> _createTag() async {
    final result = await showDialog<_TagFormResult>(
      context: context,
      builder: (_) => const _TagEditDialog(),
    );
    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    await widget.tagRepository.createTag(
      Tag(
        id: 'tag_${now.microsecondsSinceEpoch}',
        name: result.name,
        color: result.color,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    _refreshMetadata();
    _showSnackBar(context, '태그를 추가했습니다.');
  }

  Future<void> _editTag(Tag tag) async {
    final result = await showDialog<_TagFormResult>(
      context: context,
      builder: (_) => _TagEditDialog(tag: tag),
    );
    if (result == null || !mounted) {
      return;
    }

    if (result.deleteRequested) {
      final confirmed = await _confirmDelete(
        title: '태그 삭제',
        message: '태그를 삭제해도 작업은 삭제되지 않고, 연결만 해제됩니다.',
      );
      if (!confirmed || !mounted) {
        return;
      }
      await widget.tagRepository.deleteTag(tag.id);
      if (!mounted) {
        return;
      }
      _refreshMetadata();
      _showSnackBar(context, '태그를 삭제했습니다.');
      return;
    }

    final now = DateTime.now();
    await widget.tagRepository.updateTag(
      Tag(
        id: tag.id,
        name: result.name,
        color: result.color,
        createdAt: tag.createdAt,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    _refreshMetadata();
    _showSnackBar(context, '태그를 수정했습니다.');
  }

  Future<void> _createFolder(List<Folder> folders) async {
    final result = await showDialog<_FolderFormResult>(
      context: context,
      builder: (_) => _FolderEditDialog(folders: folders),
    );
    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    await widget.folderRepository.createFolder(
      Folder(
        id: 'folder_${now.microsecondsSinceEpoch}',
        name: result.name,
        color: result.color,
        icon: 'folder',
        parentFolderId: result.parentFolderId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    _refreshMetadata();
    _showSnackBar(context, '폴더를 추가했습니다.');
  }

  Future<void> _editFolder(Folder folder, List<Folder> folders) async {
    final result = await showDialog<_FolderFormResult>(
      context: context,
      builder: (_) => _FolderEditDialog(folder: folder, folders: folders),
    );
    if (result == null || !mounted) {
      return;
    }

    if (result.deleteRequested) {
      final confirmed = await _confirmDelete(
        title: '폴더 삭제',
        message: '폴더를 삭제해도 작업은 삭제되지 않고, 연결만 해제됩니다.',
      );
      if (!confirmed || !mounted) {
        return;
      }
      await widget.folderRepository.deleteFolder(folder.id);
      if (!mounted) {
        return;
      }
      _refreshMetadata();
      _showSnackBar(context, '폴더를 삭제했습니다.');
      return;
    }

    final now = DateTime.now();
    await widget.folderRepository.updateFolder(
      Folder(
        id: folder.id,
        name: result.name,
        color: result.color,
        icon: folder.icon ?? 'folder',
        parentFolderId: result.parentFolderId,
        createdAt: folder.createdAt,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    _refreshMetadata();
    _showSnackBar(context, '폴더를 수정했습니다.');
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
        );
      },
    );
    return confirmed ?? false;
  }
}

class _MetadataTaskListScreen extends StatelessWidget {
  const _MetadataTaskListScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.tasks,
    required this.onOpenTaskDetail,
    this.childFolders = const [],
    this.onOpenFolder,
    this.onEdit,
    this.editTooltip,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Task> tasks;
  final Future<void> Function(Task task) onOpenTaskDetail;
  final List<Folder> childFolders;
  final ValueChanged<Folder>? onOpenFolder;
  final VoidCallback? onEdit;
  final String? editTooltip;

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<Task>.of(tasks)..sort(_compareMetadataTasks);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sortedTasks.length}개 작업',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton.filledTonal(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: editTooltip ?? '편집',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (childFolders.isNotEmpty) ...[
              _ChildFolderStrip(
                folders: childFolders,
                onOpenFolder: onOpenFolder,
              ),
              const SizedBox(height: 20),
            ],
            if (sortedTasks.isEmpty)
              const _EmptyBlock(message: '연결된 작업이 없습니다.')
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < sortedTasks.length; i++) ...[
                      _MetadataTaskTile(
                        task: sortedTasks[i],
                        onTap: () => onOpenTaskDetail(sortedTasks[i]),
                      ),
                      if (i != sortedTasks.length - 1)
                        const Divider(height: 1, indent: 16),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChildFolderStrip extends StatelessWidget {
  const _ChildFolderStrip({required this.folders, required this.onOpenFolder});

  final List<Folder> folders;
  final ValueChanged<Folder>? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '하위 폴더',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final folder in folders) ...[
                ActionChip(
                  avatar: Icon(
                    Icons.folder_rounded,
                    color: _colorFromHex(
                      folder.color,
                      fallback: AppTheme.successGreen,
                    ),
                    size: 18,
                  ),
                  label: Text(folder.name),
                  onPressed: onOpenFolder == null
                      ? null
                      : () => onOpenFolder!(folder),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetadataTaskTile extends StatelessWidget {
  const _MetadataTaskTile({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCompleted ? AppTheme.muted : AppTheme.ink,
          fontWeight: FontWeight.w900,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (task.dueDate != null) ...[
                _DueChip(task: task),
                const SizedBox(width: 6),
              ],
              _ColoredChip(
                label: isCompleted ? '완료' : '미완료',
                color: isCompleted ? AppTheme.successGreen : AppTheme.muted,
              ),
              const SizedBox(width: 6),
              _OriginChip(origin: task.origin),
            ],
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
    );
  }
}

class _DeletedTasksManagementScreen extends StatefulWidget {
  const _DeletedTasksManagementScreen({
    required this.tasks,
    required this.onRestoreTask,
    required this.onDeletePermanently,
  });

  final List<Task> tasks;
  final Future<void> Function(Task task) onRestoreTask;
  final Future<void> Function(Task task) onDeletePermanently;

  @override
  State<_DeletedTasksManagementScreen> createState() =>
      _DeletedTasksManagementScreenState();
}

class _DeletedTasksManagementScreenState
    extends State<_DeletedTasksManagementScreen> {
  late List<Task> _tasks;
  final Set<String> _busyTaskIds = {};

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.of(widget.tasks)..sort(_compareDeletedTasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('삭제된 작업')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.dangerRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '삭제한 작업',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_tasks.length}개 작업',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_tasks.isEmpty)
              const _EmptyBlock(message: '삭제된 작업이 없습니다.')
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _tasks.length; i++) ...[
                      _DeletedManagementTaskTile(
                        task: _tasks[i],
                        isBusy: _busyTaskIds.contains(_tasks[i].id),
                        onRestore: () => _restoreTask(_tasks[i]),
                        onDeletePermanently: () =>
                            _confirmDeletePermanently(_tasks[i]),
                      ),
                      if (i != _tasks.length - 1)
                        const Divider(height: 1, indent: 16),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreTask(Task task) async {
    if (_busyTaskIds.contains(task.id)) {
      return;
    }
    setState(() {
      _busyTaskIds.add(task.id);
    });

    try {
      await widget.onRestoreTask(task);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks.removeWhere((item) => item.id == task.id);
        _busyTaskIds.remove(task.id);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyTaskIds.remove(task.id);
      });
      _showSnackBar(context, '작업 복구에 실패했습니다.');
    }
  }

  Future<void> _confirmDeletePermanently(Task task) async {
    if (_busyTaskIds.contains(task.id)) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영구 삭제'),
        content: Text('"${task.title}"을 완전히 삭제할까요? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _deletePermanently(task);
    }
  }

  Future<void> _deletePermanently(Task task) async {
    setState(() {
      _busyTaskIds.add(task.id);
    });

    try {
      await widget.onDeletePermanently(task);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks.removeWhere((item) => item.id == task.id);
        _busyTaskIds.remove(task.id);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyTaskIds.remove(task.id);
      });
      _showSnackBar(context, '작업 영구 삭제에 실패했습니다.');
    }
  }
}

class _DeletedManagementTaskTile extends StatelessWidget {
  const _DeletedManagementTaskTile({
    required this.task,
    required this.isBusy,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final Task task;
  final bool isBusy;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (task.dueDate != null) ...[
                  _DueChip(task: task),
                  const SizedBox(width: 6),
                ],
                _OriginChip(origin: task.origin),
                if (task.deletedAt != null) ...[
                  const SizedBox(width: 6),
                  _NeutralChip(label: '삭제 ${_shortDateLabel(task.deletedAt!)}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isBusy ? null : onRestore,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('복구'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: isBusy ? null : onDeletePermanently,
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('영구 삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({
    required this.settingsRepository,
    required this.isEcampusLoggedIn,
    required this.onSettingsChanged,
    required this.onOpenSync,
    required this.onClearEcampusSession,
    required this.localNotificationService,
  });

  final SettingsRepository settingsRepository;
  final bool isEcampusLoggedIn;
  final VoidCallback onSettingsChanged;
  final Future<void> Function() onOpenSync;
  final Future<void> Function() onClearEcampusSession;
  final LocalNotificationService localNotificationService;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late Future<AppSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = widget.settingsRepository.getSettings();
  }

  Future<void> _saveSettings(AppSettings settings) async {
    final saved = await widget.settingsRepository.saveSettings(settings);
    if (!mounted) {
      return;
    }
    setState(() {
      _settingsFuture = Future.value(saved);
    });
    widget.onSettingsChanged();
  }

  Future<void> _setDefaultNotificationEnabled(
    AppSettings settings,
    bool enabled,
  ) async {
    if (enabled) {
      await widget.localNotificationService.requestPermission();
    }
    await _saveSettings(settings.copyWith(defaultNotificationEnabled: enabled));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        final settings =
            snapshot.data ??
            const AppSettings(
              autoSyncEnabled: false,
              saveEcampusAccount: false,
              defaultNotificationEnabled: true,
              defaultNotificationDays: 60,
              defaultNotificationTime: 'relative',
              urgentDueDays: 3,
            );
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
            children: [
              _PageTitle(title: '설정'),
              const SizedBox(height: 28),
              _SettingsSection(
                title: 'e-campus 연동',
                children: [
                  _SettingsActionRow(
                    icon: Icons.sync_rounded,
                    title: 'e-campus 동기화',
                    subtitle: 'WebView 로그인 후 todo를 가져옵니다.',
                    onTap: () => unawaited(widget.onOpenSync()),
                  ),
                  _SettingsInfoRow(
                    icon: Icons.lock_outline_rounded,
                    title: '로그인 세션',
                    value: widget.isEcampusLoggedIn ? '로그인됨' : '로그인 필요',
                    subtitle: '아이디와 비밀번호는 저장하지 않습니다.',
                  ),
                  _SettingsActionRow(
                    icon: Icons.cleaning_services_outlined,
                    title: '세션/쿠키 정리',
                    subtitle: '이 기기의 e-campus 로그인 정보를 삭제합니다.',
                    onTap: () => unawaited(widget.onClearEcampusSession()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: '알림',
                children: [
                  _SettingsSwitchRow(
                    icon: Icons.notifications_rounded,
                    title: '기본 알림',
                    value: settings.defaultNotificationEnabled,
                    subtitle: settings.defaultNotificationEnabled
                        ? _notificationOffsetLabel(
                            settings.defaultNotificationDays,
                          )
                        : '꺼짐',
                    onChanged: isLoading
                        ? null
                        : (value) =>
                              _setDefaultNotificationEnabled(settings, value),
                  ),
                  if (settings.defaultNotificationEnabled) ...[
                    _SettingsInfoRow(
                      icon: Icons.access_time_rounded,
                      title: '알림 시점',
                      value: _notificationOffsetLabel(
                        settings.defaultNotificationDays,
                      ),
                      onTap: isLoading
                          ? null
                          : () => _pickDefaultNotificationOffset(settings),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: '홈 표시',
                children: [
                  _SettingsInfoRow(
                    icon: Icons.access_time_rounded,
                    title: '마감 임박 기준',
                    value: '${settings.urgentDueDays}일 이내',
                    onTap: isLoading
                        ? null
                        : () => _pickUrgentDueDays(settings),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDefaultNotificationOffset(AppSettings settings) async {
    final minutes = await _pickNotificationOffsetMinutes(
      title: '알림 시점',
      selected: settings.defaultNotificationDays,
    );
    if (minutes != null) {
      await _saveSettings(
        settings.copyWith(
          defaultNotificationDays: minutes,
          defaultNotificationTime: 'relative',
        ),
      );
    }
  }

  Future<void> _pickUrgentDueDays(AppSettings settings) async {
    final days = await _pickDaySlider(
      title: '마감 임박 기준',
      selected: settings.urgentDueDays,
      min: 1,
      max: 14,
      labelBuilder: (days) => '$days일 이내',
    );
    if (days != null) {
      await _saveSettings(settings.copyWith(urgentDueDays: days));
    }
  }

  Future<int?> _pickNotificationOffsetMinutes({
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

  Future<int?> _pickDaySlider({
    required String title,
    required int selected,
    required int min,
    required int max,
    required String Function(int days) labelBuilder,
  }) {
    var current = selected.clamp(min, max);
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _ColoredChip(
                      label: labelBuilder(current),
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Slider(
                    value: current.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    label: labelBuilder(current),
                    onChanged: (value) {
                      setSheetState(() {
                        current = value.round();
                      });
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(current),
                      child: const Text('적용'),
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

class _SyncLoadingDialog extends StatelessWidget {
  const _SyncLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'e-campus 동기화 중',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'todo를 가져와 기존 작업과 비교하고 있습니다.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
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

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onOpenDetail,
    required this.subTaskRepository,
    required this.metadata,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpenDetail;
  final SubTaskRepository subTaskRepository;
  final _TaskMetadataLookup metadata;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.dueDate != null && _isOverdue(task.dueDate!);

    return InkWell(
      onTap: onOpenDetail,
      child: Stack(
        children: [
          if (isOverdue && !isCompleted)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 4, color: AppTheme.dangerRed),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              isCompleted ? 10 : 14,
              14,
              isCompleted ? 10 : 14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _StatusCheckbox(task: task, onTap: onToggle),
                    if (!isCompleted) ...[
                      const SizedBox(height: 14),
                      _PriorityDot(priority: task.priority),
                    ],
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCompleted
                                    ? AppTheme.muted
                                    : AppTheme.ink,
                                fontSize: isCompleted ? 15 : 16,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox.square(
                            dimension: 32,
                            child: IconButton(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                              ),
                              color: AppTheme.muted,
                              tooltip: '삭제',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      if (!isCompleted) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: _TaskMetaStrip(task: task, metadata: metadata),
                        ),
                        const SizedBox(height: 2),
                        _SubTaskProgressView(
                          taskId: task.id,
                          subTaskRepository: subTaskRepository,
                        ),
                      ],
                    ],
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
    required this.enableReorder,
    required this.metadata,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onDeleteTask;
  final ValueChanged<Task> onOpenTaskDetail;
  final SubTaskRepository subTaskRepository;
  final Future<void> Function(List<Task> orderedTasks) onReorderTasks;
  final bool enableReorder;
  final _TaskMetadataLookup metadata;

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
    final previousSignature = _taskListSignature(_orderedTasks);
    final nextSignature = _taskListSignature(widget.tasks);

    if (previousSignature != nextSignature) {
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
          final reorderedTasksWithOrder = _tasksWithSequentialSortOrder(
            reorderedTasks,
          );

          setState(() {
            _orderedTasks = reorderedTasksWithOrder;
          });

          try {
            await widget.onReorderTasks(reorderedTasksWithOrder);
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
              _MaybeReorderableTask(
                index: index,
                enabled: widget.enableReorder,
                child: _TaskListTile(
                  task: task,
                  onToggle: () => widget.onToggleTask(task),
                  onDelete: () => widget.onDeleteTask(task),
                  onOpenDetail: () => widget.onOpenTaskDetail(task),
                  subTaskRepository: widget.subTaskRepository,
                  metadata: widget.metadata,
                ),
              ),
              if (index != _orderedTasks.length - 1) const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}

class _MaybeReorderableTask extends StatelessWidget {
  const _MaybeReorderableTask({
    required this.index,
    required this.enabled,
    required this.child,
  });

  final int index;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return ReorderableDelayedDragStartListener(index: index, child: child);
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

class _CompletedBulkDeleteButton extends StatelessWidget {
  const _CompletedBulkDeleteButton({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: count == 0 ? null : onPressed,
        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
        label: Text('완료 전체 삭제 ($count)'),
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

class _TaskMetaStrip extends StatelessWidget {
  const _TaskMetaStrip({required this.task, required this.metadata});

  final Task task;
  final _TaskMetadataLookup metadata;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (task.dueDate != null) ...[
            _DueChip(task: task),
            const SizedBox(width: 6),
          ],
          _OriginChip(origin: task.origin),
          if (metadata.foldersFor(task).isNotEmpty ||
              metadata.tagsFor(task).isNotEmpty) ...[
            const SizedBox(width: 6),
            metadata_picker.TaskMetadataChips(
              tags: metadata.tagsFor(task),
              folders: metadata.foldersFor(task),
            ),
          ],
          if (task.ecampus?.sourceCourse != null) ...[
            const SizedBox(width: 6),
            _NeutralChip(label: task.ecampus!.sourceCourse!),
          ],
        ],
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
      label: _isOverdue(dueDate)
          ? '마감 지남 · ${_shortDateLabel(dueDate)}'
          : _dueLabel(dueDate),
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
      color: AppTheme.primaryBlue,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 11,
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
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '서브 작업 ${progress.doneCount}/${progress.totalCount} 완료',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${progress.percent}%',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 4,
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

class _SortSelector extends StatelessWidget {
  const _SortSelector({required this.value, required this.onChanged});

  final _TaskSort value;
  final ValueChanged<_TaskSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.sort_rounded),
          tooltip: '정렬: ${value.label}',
        );
      },
      menuChildren: [
        for (final sort in _TaskSort.values)
          MenuItemButton(
            onPressed: () => onChanged(sort),
            leadingIcon: value == sort
                ? const Icon(Icons.check_rounded)
                : const SizedBox.square(dimension: 24),
            child: Text(sort.label),
          ),
      ],
    );
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({required this.value, required this.onChanged});

  final _TaskFilter value;
  final ValueChanged<_TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: '보기: ${value.label}',
        );
      },
      menuChildren: [
        for (final filter in _TaskFilter.values)
          MenuItemButton(
            onPressed: () => onChanged(filter),
            leadingIcon: value == filter
                ? const Icon(Icons.check_rounded)
                : const SizedBox.square(dimension: 24),
            child: Text(filter.label),
          ),
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
  const _ManagementSection({
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ?action,
          ],
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
    this.onTap,
    this.onEdit,
    this.editTooltip,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String? editTooltip;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onEdit != null
          ? IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: editTooltip ?? '편집',
            )
          : trailing == null
          ? const Icon(Icons.chevron_right_rounded, color: AppTheme.muted)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.muted,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.muted,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ManagementLoadingRow extends StatelessWidget {
  const _ManagementLoadingRow();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text('불러오는 중'),
    );
  }
}

class _ManagementEmptyRow extends StatelessWidget {
  const _ManagementEmptyRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline_rounded, color: AppTheme.muted),
      title: Text(
        message,
        style: const TextStyle(
          color: AppTheme.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TagEditDialog extends StatefulWidget {
  const _TagEditDialog({this.tag});

  final Tag? tag;

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _colorController = TextEditingController(
      text: _normalizeHex(widget.tag?.color ?? '#3B82F6'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _colorFromHex(_colorController.text);
    return AlertDialog(
      title: Text(widget.tag == null ? '태그 추가' : '태그 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '태그 이름'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const Text('색상', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _metadataColorOptions)
                  _ColorOptionButton(
                    color: _colorFromHex(color),
                    selected: _normalizeHex(_colorController.text) == color,
                    onTap: () {
                      setState(() {
                        _colorController.text = color;
                        _errorText = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: '직접 입력',
                hintText: '#3B82F6',
                errorText: _errorText,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 18, height: 18),
                  ),
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.tag != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_TagFormResult.delete()),
            child: const Text('삭제'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final color = _normalizeHex(_colorController.text);
    if (name.isEmpty) {
      setState(() => _errorText = null);
      _showSnackBar(context, '이름을 입력해주세요.');
      return;
    }
    if (!_isValidHexColor(color)) {
      setState(() => _errorText = '#RRGGBB 형식으로 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(_TagFormResult(name: name, color: color));
  }
}

class _FolderEditDialog extends StatefulWidget {
  const _FolderEditDialog({required this.folders, this.folder});

  final Folder? folder;
  final List<Folder> folders;

  @override
  State<_FolderEditDialog> createState() => _FolderEditDialogState();
}

class _FolderEditDialogState extends State<_FolderEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  String? _parentFolderId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    _colorController = TextEditingController(
      text: _normalizeHex(widget.folder?.color ?? '#22C55E'),
    );
    _parentFolderId = widget.folder?.parentFolderId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _colorFromHex(
      _colorController.text,
      fallback: AppTheme.successGreen,
    );
    return AlertDialog(
      title: Text(widget.folder == null ? '폴더 추가' : '폴더 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '폴더 이름'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const Text('색상', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _metadataColorOptions)
                  _ColorOptionButton(
                    color: _colorFromHex(color),
                    selected: _normalizeHex(_colorController.text) == color,
                    onTap: () {
                      setState(() {
                        _colorController.text = color;
                        _errorText = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: '직접 입력',
                hintText: '#22C55E',
                errorText: _errorText,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.folder_rounded,
                    color: selectedColor,
                    size: 22,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            if (_parentCandidates.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _parentFolderId,
                decoration: const InputDecoration(labelText: '상위 폴더'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('없음'),
                  ),
                  for (final folder in _parentCandidates)
                    DropdownMenuItem<String?>(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _parentFolderId = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.folder != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_FolderFormResult.delete());
            },
            child: const Text('삭제'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final color = _normalizeHex(_colorController.text);
    if (name.isEmpty) {
      setState(() => _errorText = null);
      _showSnackBar(context, '이름을 입력해주세요.');
      return;
    }
    if (!_isValidHexColor(color)) {
      setState(() => _errorText = '#RRGGBB 형식으로 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(
      _FolderFormResult(
        name: name,
        color: color,
        parentFolderId: _parentFolderId,
      ),
    );
  }

  List<Folder> get _parentCandidates {
    final editingId = widget.folder?.id;
    return widget.folders
        .where((folder) => !_isSelfOrDescendant(folder.id, editingId))
        .toList(growable: false);
  }

  bool _isSelfOrDescendant(String candidateId, String? editingId) {
    if (editingId == null) {
      return false;
    }
    if (candidateId == editingId) {
      return true;
    }

    var current = widget.folders
        .where((folder) => folder.id == candidateId)
        .firstOrNull;
    while (current?.parentFolderId != null) {
      if (current!.parentFolderId == editingId) {
        return true;
      }
      current = widget.folders
          .where((folder) => folder.id == current!.parentFolderId)
          .firstOrNull;
    }
    return false;
  }
}

class _ColorOptionButton extends StatelessWidget {
  const _ColorOptionButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}

class _TagFormResult {
  const _TagFormResult({required this.name, required this.color})
    : deleteRequested = false;

  const _TagFormResult.delete() : name = '', color = '', deleteRequested = true;

  final String name;
  final String color;
  final bool deleteRequested;
}

class _FolderFormResult {
  const _FolderFormResult({
    required this.name,
    required this.color,
    this.parentFolderId,
  }) : deleteRequested = false;

  const _FolderFormResult.delete()
    : name = '',
      color = '',
      parentFolderId = null,
      deleteRequested = true;

  final String name;
  final String color;
  final String? parentFolderId;
  final bool deleteRequested;
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
      minLeadingWidth: 28,
      leading: _SettingsIcon(icon: icon, color: AppTheme.successGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
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
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
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
  overdue('마감 지남'),
  deleted('삭제됨');

  const _TaskFilter(this.label);

  final String label;
}

enum _TaskSort {
  userOrder('사용자 지정'),
  dueDate('마감일'),
  priority('우선순위'),
  createdAt('생성일');

  const _TaskSort(this.label);

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

bool _isUrgent(Task task, int urgentDueDays) {
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return false;
  }
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final days = dueDay.difference(startOfToday).inDays;
  return days >= 0 && days <= urgentDueDays && !_isDueToday(task);
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

int Function(Task a, Task b) _compareTasksBySort(_TaskSort sort) {
  return switch (sort) {
    _TaskSort.userOrder => _compareUserOrder,
    _TaskSort.dueDate => _compareDueDate,
    _TaskSort.priority => _comparePriority,
    _TaskSort.createdAt => _compareCreatedAt,
  };
}

int _compareUserOrder(Task a, Task b) {
  final order = a.sortOrder.compareTo(b.sortOrder);
  if (order != 0) {
    return order;
  }
  return a.createdAt.compareTo(b.createdAt);
}

int _comparePriority(Task a, Task b) {
  final priority = _priorityRank(
    b.priority,
  ).compareTo(_priorityRank(a.priority));
  if (priority != 0) {
    return priority;
  }
  return _compareDueDate(a, b);
}

int _compareCreatedAt(Task a, Task b) {
  return b.createdAt.compareTo(a.createdAt);
}

int _compareDeletedTasks(Task a, Task b) {
  final aDeletedAt = a.deletedAt;
  final bDeletedAt = b.deletedAt;
  if (aDeletedAt == null && bDeletedAt == null) {
    return _compareCreatedAt(a, b);
  }
  if (aDeletedAt == null) {
    return 1;
  }
  if (bDeletedAt == null) {
    return -1;
  }
  return bDeletedAt.compareTo(aDeletedAt);
}

int _compareMetadataTasks(Task a, Task b) {
  final status = _metadataStatusRank(
    a.status,
  ).compareTo(_metadataStatusRank(b.status));
  if (status != 0) {
    return status;
  }
  return _compareDueDate(a, b);
}

int _metadataStatusRank(TaskStatus status) {
  return switch (status) {
    TaskStatus.active => 0,
    TaskStatus.completed => 1,
    TaskStatus.deleted => 2,
    TaskStatus.excluded => 3,
  };
}

int _priorityRank(TaskPriority? priority) {
  return switch (priority) {
    TaskPriority.high => 3,
    TaskPriority.medium => 2,
    TaskPriority.low => 1,
    null => 0,
  };
}

List<Task> _tasksWithSequentialSortOrder(List<Task> tasks) {
  return [
    for (var index = 0; index < tasks.length; index++)
      _copyTaskWithSortOrder(tasks[index], index),
  ];
}

Task _copyTaskWithSortOrder(Task task, int sortOrder) {
  return Task(
    id: task.id,
    origin: task.origin,
    status: task.status,
    title: task.title,
    dueDate: task.dueDate,
    priority: task.priority,
    memo: task.memo,
    parentTaskId: task.parentTaskId,
    tagIds: task.tagIds,
    folderIds: task.folderIds,
    ecampus: task.ecampus,
    sortOrder: sortOrder,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    completedAt: task.completedAt,
    deletedAt: task.deletedAt,
  );
}

String _taskListSignature(List<Task> tasks) {
  return tasks
      .map(
        (task) => [
          task.id,
          task.status.name,
          task.title,
          task.dueDate?.microsecondsSinceEpoch ?? '',
          task.priority?.name ?? '',
          task.sortOrder,
          task.updatedAt.microsecondsSinceEpoch,
        ].join(':'),
      )
      .join('|');
}

const _metadataColorOptions = [
  '#EF4444',
  '#F97316',
  '#EAB308',
  '#22C55E',
  '#3B82F6',
  '#8B5CF6',
  '#6B7280',
];

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

Color _colorFromHex(String? value, {Color fallback = AppTheme.primaryBlue}) {
  final normalized = _normalizeHex(value);
  if (!_isValidHexColor(normalized)) {
    return fallback;
  }
  return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
}

String _normalizeHex(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }
  final withHash = trimmed.startsWith('#') ? trimmed : '#$trimmed';
  return withHash.toUpperCase();
}

bool _isValidHexColor(String value) {
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(value);
}

String _folderSubtitle(Folder folder, List<Folder> folders) {
  final parentId = folder.parentFolderId;
  if (parentId == null) {
    return '상위 폴더 없음';
  }
  final parent = folders.where((folder) => folder.id == parentId).firstOrNull;
  return parent == null ? '상위 폴더 없음' : '상위 폴더 ${parent.name}';
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

String _shortDateLabel(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

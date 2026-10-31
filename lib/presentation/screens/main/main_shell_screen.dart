import '../../../core/utils/entity_id.dart';
import 'dart:async';
import '../../../core/utils/list_defaults.dart';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/sub_task_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/home_task_summary.dart';
import '../../../data/services/widget_update_service.dart';
import '../../services/local_notification_service.dart';
import 'mobile_home_page.dart';
import 'home_settings_menu.dart';
import '../sync/ecampus_sync_progress_screen.dart';
import '../task/task_create_screen.dart';
import '../task/task_detail_screen.dart';
import '../../widgets/task_metadata_picker.dart' as metadata_picker;
import '../../widgets/home_calendar_section.dart';

enum _DrawerAdd { folder, list, tag }

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
    required this.widgetUpdateService,
  });

  final TaskRepository taskRepository;
  final SubTaskRepository subTaskRepository;
  final NotificationRepository notificationRepository;
  final SettingsRepository settingsRepository;
  final TagRepository tagRepository;
  final FolderRepository folderRepository;
  final LocalNotificationService localNotificationService;
  final WidgetUpdateService widgetUpdateService;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  var _selectedIndex = 0;
  final _metadataManagerKey = GlobalKey<_ManagementPageState>();
  Timer? _clockRefreshTimer;
  late Future<List<Task>> _tasksFuture;
  late Future<AppSettings> _settingsFuture;
  late Future<_TaskMetadataLookup> _metadataFuture;
  var _metadataVersion = 0;
  var _isEcampusSyncing = false;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
    _settingsFuture = _loadSettings();
    _metadataFuture = _loadMetadata();
    _scheduleClockRefresh();
    _listenForWidgetLaunch();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshIfWidgetChangedTasks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshIfWidgetChangedTasks());
    }
  }

  /// 주간 위젯에서 체크한 뒤 앱 복귀 시 목록·위젯 JSON을 다시 맞춘다.
  Future<void> _refreshIfWidgetChangedTasks() async {
    final needsRefresh = await HomeWidget.getWidgetData<bool>(
      WidgetUpdateService.widgetRefreshRequiredKey,
      defaultValue: false,
    );
    if (needsRefresh != true || !mounted) {
      return;
    }

    // Read the shared task list only after weekly widget changes reach the DB.
    await widget.widgetUpdateService.applyPendingWidgetCompletions();
    if (!mounted) {
      return;
    }
    await HomeWidget.saveWidgetData(
      WidgetUpdateService.widgetRefreshRequiredKey,
      null,
    );
    if (mounted) {
      _refreshTasksAndMetadata();
    }
  }

  Future<List<Task>> _loadTasks() {
    return widget.taskRepository.getTasks(includeArchived: true);
  }

  Future<AppSettings> _loadSettings() async {
    final settings = await widget.settingsRepository.getSettings();
    return settings;
  }

  void _scheduleClockRefresh() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _clockRefreshTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _refreshHomeWidget();
      _scheduleClockRefresh();
    });
  }

  Future<void> _listenForWidgetLaunch() async {
    final launchedUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launchedUri != null) {
      _openHomeFromWidget();
    }
    HomeWidget.widgetClicked.listen((_) {
      _openHomeFromWidget();
    });
  }

  void _openHomeFromWidget() {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _refreshHomeWidget() {
    unawaited(widget.widgetUpdateService.refresh());
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _loadTasks();
    });
    _refreshHomeWidget();
  }

  Future<_TaskMetadataLookup> _loadMetadata() async {
    final tags = await widget.tagRepository.getTags();
    final lists = await widget.folderRepository.getFolders();
    final repository = widget.folderRepository;
    final groups = repository is GroupedListRepository
        ? await (repository as GroupedListRepository).getGroups()
        : const <FolderGroup>[];
    return _TaskMetadataLookup(tags: tags, lists: lists, groups: groups);
  }

  void _refreshMetadata() {
    setState(() {
      _settingsFuture = _loadSettings();
      _metadataFuture = _loadMetadata();
      _metadataVersion++;
    });
  }

  void _refreshTasksAndMetadata() {
    setState(() {
      _tasksFuture = _loadTasks();
      _settingsFuture = _loadSettings();
      _metadataFuture = _loadMetadata();
      _metadataVersion++;
    });
    _refreshHomeWidget();
  }

  Future<void> _openEcampusSync() async {
    if (_isEcampusSyncing) {
      _showSnackBar(context, 'eCampus 가져오기가 이미 진행 중입니다.');
      return;
    }

    setState(() {
      _isEcampusSyncing = true;
    });
    try {
      final didChange = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EcampusSyncProgressScreen(
            taskRepository: widget.taskRepository,
            tagRepository: widget.tagRepository,
            folderRepository: widget.folderRepository,
            settingsRepository: widget.settingsRepository,
            notificationRepository: widget.notificationRepository,
            localNotificationService: widget.localNotificationService,
            onOpenTask: _openTaskDetail,
            onOrganizeUnassigned: widget.taskRepository is EcampusListOrganizer
                ? (ids) => (widget.taskRepository as EcampusListOrganizer)
                      .organizeUnassignedEcampusTasks(ids)
                : null,
          ),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) {
        return;
      }
      if (didChange == true) {
        _refreshTasksAndMetadata();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEcampusSyncing = false;
        });
      }
    }
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

  Future<void> _allowExcludedTaskSync(Task task) async {
    await _cancelTaskNotification(task.id);
    await widget.taskRepository.deletePermanently(task.id);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '다음 동기화부터 다시 가져올 수 있습니다.');
  }

  Future<void> _deleteTaskPermanently(Task task) async {
    await _cancelTaskNotification(task.id);
    await widget.taskRepository.deletePermanently(task.id);
    if (!mounted) {
      return;
    }

    _refreshTasks();
    _showSnackBar(context, '작업을 영구 삭제했습니다.');
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
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: .9,
        child: TaskDetailScreen(
          taskId: task.id,
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

  Future<void> _openTaskCreate({DateTime? initialDay}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskCreateScreen(
          initialDueDate: initialDay == null
              ? null
              : DateTime(
                  initialDay.year,
                  initialDay.month,
                  initialDay.day,
                  23,
                  59,
                ),
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

  // Drawer actions reuse management dialogs and their repository save handlers.
  Future<void> _addFromDrawer(_DrawerAdd kind, {String? groupId}) async {
    final manager = _metadataManagerKey.currentState;
    if (manager == null) return;
    try {
      if (kind == _DrawerAdd.folder) {
        await manager._editGroup();
      } else {
        final lists = await manager._loadLists();
        if (!mounted || !manager.mounted) return;
        if (kind == _DrawerAdd.list) {
          await manager._createFolder(lists, initialGroupId: groupId);
        } else {
          await manager._createTag(lists);
        }
      }
    } catch (_) {
      if (mounted) _showSnackBar(context, '항목을 추가하지 못했습니다. 다시 시도해주세요.');
    }
  }

  Future<void> _editFromDrawer({
    FolderGroup? group,
    Folder? list,
    Tag? tag,
  }) async {
    final manager = _metadataManagerKey.currentState;
    if (manager == null) return;
    try {
      final lists = await manager._loadLists();
      if (!mounted || !manager.mounted) return;
      if (group != null) {
        await manager._editGroup(group);
      } else if (list != null) {
        await manager._editFolder(list, lists);
      } else if (tag != null) {
        await manager._editTag(tag, lists);
      }
    } catch (_) {
      if (mounted) _showSnackBar(context, '항목을 수정하지 못했습니다. 다시 시도해주세요.');
    }
  }

  Future<void> _moveDrawerList(
    String id,
    String? groupId,
    String? beforeId,
  ) async {
    final repository = widget.folderRepository;
    if (repository is! GroupedListRepository) return;
    await (repository as GroupedListRepository).moveList(
      id,
      groupId,
      beforeListId: beforeId,
    );
    if (mounted) _refreshMetadata();
  }

  Future<void> _moveDrawerTag(String id, String? beforeId) async {
    final latest = await widget.settingsRepository.getSettings();
    final tags = await widget.tagRepository.getTags();
    tags.sort((a, b) {
      final left = latest.tagSortOrders[a.id];
      final right = latest.tagSortOrders[b.id];
      if (left != null && right != null && left != right) {
        return left.compareTo(right);
      }
      if (left != null && right == null) return -1;
      if (left == null && right != null) return 1;
      return a.name.compareTo(b.name);
    });
    final ids = tags.map((tag) => tag.id).toList();
    if (!ids.remove(id) || (beforeId != null && !ids.contains(beforeId))) {
      throw StateError('이동할 태그가 변경됐습니다.');
    }
    ids.insert(beforeId == null ? ids.length : ids.indexOf(beforeId), id);
    final saved = await widget.settingsRepository.saveSettings(
      latest.copyWith(
        tagSortOrders: {for (var i = 0; i < ids.length; i++) ids[i]: i},
      ),
    );
    if (mounted) _settingsSaved(saved);
  }

  Future<void> _openQuickAdd({
    String? listId,
    List<String> tagIds = const [],
  }) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => TaskCreateScreen(
        quickAdd: true,
        initialListId: listId,
        initialTagIds: tagIds,
        taskRepository: widget.taskRepository,
        subTaskRepository: widget.subTaskRepository,
        notificationRepository: widget.notificationRepository,
        settingsRepository: widget.settingsRepository,
        tagRepository: widget.tagRepository,
        folderRepository: widget.folderRepository,
        localNotificationService: widget.localNotificationService,
      ),
    );
    if (mounted) _refreshTasksAndMetadata();
  }

  void _settingsSaved(AppSettings saved) {
    if (!mounted) return;
    setState(() {
      _settingsFuture = Future.value(saved);
    });
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
                  MobileHomePage(
                    isActive: _selectedIndex == 0,
                    tasks: tasks,
                    isLoading: isLoading,
                    settings: settings,
                    settingsReady: settingsSnapshot.hasData,
                    settingsRepository: widget.settingsRepository,
                    tags: metadata.tags,
                    lists: metadata.lists,
                    groups: metadata.groups,
                    onSettingsSaved: _settingsSaved,
                    onMoveList: _moveDrawerList,
                    onMoveTag: _moveDrawerTag,
                    onAllowExcludedTaskSync: _allowExcludedTaskSync,
                    onRefresh: _refreshTasks,
                    onImport: _openEcampusSync,
                    onSettings: (anchor) => showHomeSettingsMenu(
                      anchor: anchor,
                      settings: settings,
                      repository: widget.settingsRepository,
                      notifications: widget.localNotificationService,
                      onSaved: _settingsSaved,
                    ),
                    onAddFolder:
                        widget.folderRepository is GroupedListRepository
                        ? () => _addFromDrawer(_DrawerAdd.folder)
                        : null,
                    onAddList: () => _addFromDrawer(_DrawerAdd.list),
                    onAddTag: () => _addFromDrawer(_DrawerAdd.tag),
                    onEditFolder: (group) => _editFromDrawer(group: group),
                    onAddListToFolder: (group) =>
                        _addFromDrawer(_DrawerAdd.list, groupId: group.id),
                    onEditList: (list) => _editFromDrawer(list: list),
                    onAddTaskToList: (list) => _openQuickAdd(listId: list.id),
                    onEditTag: (tag) => _editFromDrawer(tag: tag),
                    onAddTaskWithTag: (tag) => _openQuickAdd(tagIds: [tag.id]),
                    onToggleTask: _toggleTaskCompletion,
                    onOpenTask: _openTaskDetail,
                    onRestoreTask: _restoreTask,
                    onDeletePermanently: _deleteTaskPermanently,
                    onDeleteTask: _deleteTask,
                  ),
                  SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        HomeCalendarSection(
                          tasks: tasks,
                          isLoading: isLoading,
                          onCreateTask: (day) =>
                              _openTaskCreate(initialDay: day),
                          onOpenTask: _openTaskDetail,
                          onToggleTask: _toggleTaskCompletion,
                          onDeleteTask: _deleteTask,
                        ),
                      ],
                    ),
                  ),
                  _ManagementPage(
                    key: _metadataManagerKey,
                    tasks: tasks,
                    loadTasks: _loadTasks,
                    settings: settings,
                    tagRepository: widget.tagRepository,
                    folderRepository: widget.folderRepository,
                    subTaskRepository: widget.subTaskRepository,
                    metadataVersion: _metadataVersion,
                    onMetadataChanged: _refreshMetadata,
                    onSettingsChanged: (value) async {
                      _settingsSaved(
                        await widget.settingsRepository.saveSettings(value),
                      );
                    },
                    onToggleTask: _toggleTaskCompletion,
                    onDeleteTask: _deleteTask,
                    onOpenTaskDetail: _openTaskDetail,
                    onRestoreTask: _restoreTask,
                    onDeletePermanently: _deleteTaskPermanently,
                  ),
                ];
                return Scaffold(
                  body: IndexedStack(index: _selectedIndex, children: pages),
                  bottomNavigationBar: NavigationBar(
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                    selectedIndex: _selectedIndex == 1 ? 2 : 0,
                    onDestinationSelected: (index) {
                      if (index == 1) {
                        _openQuickAdd();
                        return;
                      }
                      setState(() => _selectedIndex = index == 2 ? 1 : 0);
                    },
                    destinations: const [
                      NavigationDestination(
                        key: ValueKey('nav-home'),
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: '홈',
                      ),
                      NavigationDestination(
                        key: ValueKey('nav-add'),
                        icon: Icon(Icons.add_rounded),
                        label: '빠른 추가',
                      ),
                      NavigationDestination(
                        key: ValueKey('nav-calendar'),
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month_rounded),
                        label: '캘린더',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

bool _isHiddenInMainList(Task task) {
  return task.status == TaskStatus.deleted ||
      task.status == TaskStatus.excluded;
}

class _TaskMetadataLookup {
  const _TaskMetadataLookup({
    required List<Tag> tags,
    this.lists = const [],
    this.groups = const [],
  }) : _tags = tags;

  const _TaskMetadataLookup.empty()
    : _tags = const [],
      lists = const [],
      groups = const [];

  final List<Tag> _tags;
  final List<Folder> lists;
  final List<FolderGroup> groups;

  List<Tag> get tags => _tags;

  Tag? tagById(String? id) {
    if (id == null) {
      return null;
    }
    return _tags.where((tag) => tag.id == id).firstOrNull;
  }

  List<Tag> tagsFor(Task task) {
    final ids = task.tagIds.toSet();
    return _tags.where((tag) => ids.contains(tag.id)).toList(growable: false);
  }
}

class _ManagementPage extends StatefulWidget {
  const _ManagementPage({
    super.key,
    required this.tasks,
    required this.loadTasks,
    required this.settings,
    required this.tagRepository,
    required this.folderRepository,
    required this.subTaskRepository,
    required this.metadataVersion,
    required this.onMetadataChanged,
    required this.onSettingsChanged,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onOpenTaskDetail,
    required this.onRestoreTask,
    required this.onDeletePermanently,
  });

  final List<Task> tasks;
  final Future<List<Task>> Function() loadTasks;
  final AppSettings settings;
  final TagRepository tagRepository;
  final FolderRepository folderRepository;
  final SubTaskRepository subTaskRepository;
  final int metadataVersion;
  final VoidCallback onMetadataChanged;
  final Future<void> Function(AppSettings settings) onSettingsChanged;
  final Future<void> Function(Task task) onToggleTask;
  final Future<void> Function(Task task) onDeleteTask;
  final Future<void> Function(Task task) onOpenTaskDetail;
  final Future<void> Function(Task task) onRestoreTask;
  final Future<void> Function(Task task) onDeletePermanently;

  @override
  State<_ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<_ManagementPage> {
  late Future<List<Tag>> _tagsFuture;
  late Future<List<Folder>> _foldersFuture;
  var _showHiddenMetadata = false;
  List<FolderGroup> _groups = const [];
  final Set<String> _expandedGroupIds = {};

  GroupedListRepository? get _grouping =>
      widget.folderRepository is GroupedListRepository
      ? widget.folderRepository as GroupedListRepository
      : null;

  Future<List<Folder>> _loadLists() async {
    _groups = await _grouping?.getGroups() ?? [];
    return widget.folderRepository.getFolders();
  }

  @override
  void initState() {
    super.initState();
    _tagsFuture = widget.tagRepository.getTags();
    _foldersFuture = _loadLists();
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
      _foldersFuture = _loadLists();
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
            builder: (context, tagSnapshot) {
              return FutureBuilder<List<Folder>>(
                future: _foldersFuture,
                builder: (context, folderSnapshot) {
                  final tags = tagSnapshot.data ?? const <Tag>[];
                  final folders = folderSnapshot.data ?? const <Folder>[];
                  final treeRows = [
                    ..._groupedListRows(folders, tags),
                    ..._rootTagRows(tags, folders),
                  ];
                  final isLoading =
                      (tagSnapshot.connectionState == ConnectionState.waiting &&
                          !tagSnapshot.hasData) ||
                      (folderSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !folderSnapshot.hasData);

                  return _ManagementSection(
                    title: '분류',
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              _showHiddenMetadata = !_showHiddenMetadata;
                            });
                          },
                          icon: Icon(
                            _showHiddenMetadata
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _showHiddenMetadata ? '숨김 가리기' : '숨김 보기',
                        ),
                        const SizedBox(width: 8),
                        if (_grouping != null)
                          IconButton.filledTonal(
                            onPressed: () => _editGroup(),
                            icon: const Icon(Icons.create_new_folder_outlined),
                            tooltip: '상위 폴더 추가',
                          ),
                        IconButton.filledTonal(
                          onPressed: () => _createFolder(folders),
                          icon: const Icon(
                            Icons.square_rounded,
                            color: AppTheme.successGreen,
                          ),
                          tooltip: '목록 추가',
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _createTag(folders),
                          icon: const Icon(Icons.new_label_rounded),
                          tooltip: '태그 추가',
                        ),
                      ],
                    ),
                    children: [
                      if (isLoading)
                        const _ManagementLoadingRow()
                      else if (treeRows.isEmpty)
                        const _ManagementEmptyRow(message: '항목이 없습니다.')
                      else
                        ...treeRows,
                    ],
                  );
                },
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
          reloadTasks: widget.loadTasks,
          subTaskRepository: widget.subTaskRepository,
          taskFilter: (task) =>
              !_isHiddenInMainList(task) && task.tagIds.contains(tag.id),
          onToggleTask: widget.onToggleTask,
          onDeleteTask: widget.onDeleteTask,
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

  List<Widget> _groupedListRows(List<Folder> lists, List<Tag> tags) {
    final root = lists.where((list) => list.groupId == null).toList()
      ..sort(
        (a, b) => a.id == b.id
            ? 0
            : a.id == inboxListId
            ? -1
            : b.id == inboxListId
            ? 1
            : _compareMetadataFolders(a, b),
      );
    return [
      _MetadataRootDropTarget(
        key: const ValueKey('lists-root-drop'),
        onAccept: (item) => _moveMetadataToRoot(item, lists),
        child: Column(
          children: [
            const ListTile(
              title: Text('폴더 밖'),
              subtitle: Text('목록을 여기로 끌어 놓으면 폴더 밖으로 이동합니다.'),
            ),
            ..._folderTreeRows(root, lists, tags),
          ],
        ),
      ),
      for (final group in _groups) ...[
        _ManagementRow(
          key: ValueKey('folder-group-${group.id}'),
          icon: Icons.folder_rounded,
          iconColor: AppTheme.primaryBlue,
          title: group.name,
          trailing: '${lists.where((list) => list.groupId == group.id).length}',
          expanded: _expandedGroupIds.contains(group.id),
          onTap: () => setState(() {
            if (!_expandedGroupIds.add(group.id)) {
              _expandedGroupIds.remove(group.id);
            }
          }),
          canAccept: _canMoveList,
          onAccept: (item) => _moveList(item, group.id),
          onEdit: () => _editGroup(group),
        ),
        if (_expandedGroupIds.contains(group.id))
          for (final list in lists.where((list) => list.groupId == group.id))
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                children: _folderTreeRowsFrom(
                  list,
                  lists,
                  tags: tags,
                  depth: 1,
                ),
              ),
            ),
      ],
    ];
  }

  Future<void> _editGroup([FolderGroup? group]) async {
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (_) => _FolderGroupDialog(group: group),
    );
    if (result == null || !mounted) return;
    if (result.$2) {
      final confirmed = await _confirmDelete(
        title: '상위 폴더 삭제',
        message: '안의 목록은 폴더 밖으로 이동하며 할 일과 목록은 유지됩니다.',
      );
      if (!confirmed || !mounted) return;
      await _grouping!.deleteGroup(group!.id);
    } else {
      final now = DateTime.now();
      await _grouping!.saveGroup(
        FolderGroup(
          id: group?.id ?? newEntityId(),
          name: result.$1,
          createdAt: group?.createdAt ?? now,
          updatedAt: now,
          sortOrder: group?.sortOrder ?? 0,
        ),
      );
    }
    if (mounted) _refreshMetadata();
  }

  List<Widget> _folderTreeRows(
    List<Folder> roots,
    List<Folder> folders,
    List<Tag> tags,
  ) {
    final rows = <Widget>[];
    for (final folder in roots) {
      rows.addAll(_folderTreeRowsFrom(folder, folders, tags: tags, depth: 0));
    }
    return rows;
  }

  List<Widget> _rootTagRows(List<Tag> tags, List<Folder> folders) {
    final sortedTags = List<Tag>.of(tags)..sort(_compareMetadataTags);
    final folderIds = folders.map((folder) => folder.id).toSet();
    final rootTags = sortedTags
        .where((tag) => _isRootTag(tag, folderIds))
        .where((tag) => _showHiddenMetadata || !_isTagHidden(tag.id))
        .toList(growable: false);
    return [
      for (final tag in rootTags) _tagManagementRow(tag, folders, depth: 0),
    ];
  }

  List<Widget> _folderTreeRowsFrom(
    Folder folder,
    List<Folder> folders, {
    required List<Tag> tags,
    required int depth,
  }) {
    if (!_showHiddenMetadata && _isFolderHidden(folder.id)) return [];
    return [
      _ManagementRow(
        key: ValueKey('task-list-${folder.id}'),
        icon: Icons.square_rounded,
        iconColor: _colorFromHex(folder.color ?? '#22C55E'),
        title: folder.name,
        dragItem: folder.id == inboxListId
            ? null
            : _MetadataDragItem.folder(folder.id),
        canAccept: (item) => _canMoveList(item) && item.id != folder.id,
        onAccept: folder.id == inboxListId
            ? null
            : (item) => _moveMetadataBeforeFolder(item, folder, folders),
        onTap: () => _openFolderTasks(folder, tags),
        onEdit: () => _editFolder(folder, folders),
      ),
    ];
  }

  Future<void> _openFolderTasks(Folder folder, List<Tag> tags) async {
    bool matches(Task task) =>
        !_isHiddenInMainList(task) && task.folderIds.contains(folder.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _MetadataTaskListScreen(
          title: folder.name,
          subtitle: '목록의 할 일',
          icon: Icons.square_rounded,
          iconColor: _colorFromHex(folder.color ?? '#22C55E'),
          tasks: widget.tasks.where(matches).toList(),
          reloadTasks: widget.loadTasks,
          taskFilter: matches,
          availableTags: tags,
          subTaskRepository: widget.subTaskRepository,
          onToggleTask: widget.onToggleTask,
          onDeleteTask: widget.onDeleteTask,
          onOpenTaskDetail: widget.onOpenTaskDetail,
        ),
      ),
    );
  }

  Widget _tagManagementRow(
    Tag tag,
    List<Folder> folders, {
    required int depth,
  }) {
    return _ManagementRow(
      icon: _isTagHidden(tag.id) ? Icons.visibility_off_outlined : Icons.circle,
      iconColor: _isTagHidden(tag.id)
          ? AppTheme.muted
          : _colorFromHex(tag.color),
      title: tag.name,
      depth: depth,
      dragItem: _MetadataDragItem.tag(tag.id),
      onAccept: (item) => _moveMetadataBeforeTag(item, tag, folders),
      onTap: () => _openTagTasks(tag),
      onEdit: () => _editTag(tag, folders),
      editTooltip: '태그 편집',
    );
  }

  bool _isRootTag(Tag tag, Set<String> folderIds) => true;

  int _compareMetadataTags(Tag a, Tag b) {
    final orderA = widget.settings.tagSortOrders[a.id];
    final orderB = widget.settings.tagSortOrders[b.id];
    if (orderA != null && orderB != null && orderA != orderB) {
      return orderA.compareTo(orderB);
    }
    if (orderA != null && orderB == null) {
      return -1;
    }
    if (orderA == null && orderB != null) {
      return 1;
    }
    return a.name.compareTo(b.name);
  }

  int _compareMetadataFolders(Folder a, Folder b) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) {
      return order;
    }
    return a.name.compareTo(b.name);
  }

  bool _isTagHidden(String id) => widget.settings.hiddenTagIds.contains(id);
  bool _isFolderHidden(String id) =>
      id != inboxListId && widget.settings.hiddenFolderIds.contains(id);
  Future<void> _setFolderHidden(String id, bool hidden) {
    final ids = {...widget.settings.hiddenFolderIds};
    if (hidden) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    return widget.onSettingsChanged(
      widget.settings.copyWith(hiddenFolderIds: ids),
    );
  }

  Future<void> _moveMetadataToRoot(
    _MetadataDragItem item,
    List<Folder> folders,
  ) => _moveList(item, null);

  bool _canMoveList(_MetadataDragItem item) =>
      _grouping != null &&
      item.type == _MetadataDragType.folder &&
      item.id != inboxListId;

  Future<void> _moveList(
    _MetadataDragItem item,
    String? groupId, {
    String? beforeListId,
  }) async {
    if (!_canMoveList(item)) return;
    try {
      await _grouping!.moveList(item.id, groupId, beforeListId: beforeListId);
      if (!mounted) return;
      if (groupId != null) _expandedGroupIds.add(groupId);
      _refreshMetadata();
    } catch (_) {
      if (mounted) _showSnackBar(context, '목록을 이동하지 못했습니다. 다시 시도해주세요.');
    }
  }

  Future<void> _moveMetadataBeforeFolder(
    _MetadataDragItem item,
    Folder target,
    List<Folder> folders,
  ) async {
    if (item.id == target.id) return;
    await _moveList(item, target.groupId, beforeListId: target.id);
  }

  Future<void> _moveMetadataBeforeTag(
    _MetadataDragItem item,
    Tag target,
    List<Folder> folders,
  ) async {
    if (item.type != _MetadataDragType.tag || item.id == target.id) return;
    final tags = await widget.tagRepository.getTags();
    tags.sort(_compareMetadataTags);
    final ids = tags.map((t) => t.id).toList()..remove(item.id);
    ids.insert(ids.indexOf(target.id), item.id);
    await widget.onSettingsChanged(
      widget.settings.copyWith(
        tagSortOrders: {for (var i = 0; i < ids.length; i++) ids[i]: i},
      ),
    );
    _refreshMetadata();
  }

  Future<void> _createTag(List<Folder> folders) async {
    final result = await showDialog<_TagFormResult>(
      context: context,
      builder: (_) => _TagEditDialog(folders: folders),
    );
    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    await widget.tagRepository.createTag(
      Tag(
        id: newEntityId(),
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

  Future<void> _editTag(Tag tag, List<Folder> folders) async {
    final result = await showDialog<_TagFormResult>(
      context: context,
      builder: (_) => _TagEditDialog(
        tag: tag,
        folders: folders,
        selectedFolderId: widget.settings.tagFolderIds[tag.id],
        isHidden: _isTagHidden(tag.id),
      ),
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
      final hiddenIds = {...widget.settings.hiddenTagIds}..remove(tag.id);
      final tagFolderIds = {...widget.settings.tagFolderIds}..remove(tag.id);
      final tagSortOrders = {...widget.settings.tagSortOrders}..remove(tag.id);
      await widget.onSettingsChanged(
        widget.settings.copyWith(
          hiddenTagIds: hiddenIds,
          tagFolderIds: tagFolderIds,
          tagSortOrders: tagSortOrders,
        ),
      );
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
    final hiddenIds = {...widget.settings.hiddenTagIds};
    if (result.isHidden) {
      hiddenIds.add(tag.id);
    } else {
      hiddenIds.remove(tag.id);
    }
    final tagFolderIds = {...widget.settings.tagFolderIds};
    if (result.folderId == null) {
      tagFolderIds.remove(tag.id);
    } else {
      tagFolderIds[tag.id] = result.folderId!;
    }
    await widget.onSettingsChanged(
      widget.settings.copyWith(
        hiddenTagIds: hiddenIds,
        tagFolderIds: tagFolderIds,
      ),
    );
    if (!mounted) {
      return;
    }
    _refreshMetadata();
    _showSnackBar(context, '태그를 수정했습니다.');
  }

  Future<void> _createFolder(
    List<Folder> folders, {
    String? initialGroupId,
  }) async {
    final result = await showDialog<_FolderFormResult>(
      context: context,
      builder: (_) => _FolderEditDialog(
        folders: folders,
        groups: _groups,
        initialGroupId: initialGroupId,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    await widget.folderRepository.createFolder(
      Folder(
        id: newEntityId(),
        name: result.name,
        color: result.color,
        icon: 'folder',
        parentFolderId: result.parentFolderId,
        groupId: result.groupId,
        sortOrder:
            (folders.isEmpty
                ? -1
                : folders
                      .map((f) => f.sortOrder)
                      .reduce((a, b) => a > b ? a : b)) +
            1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.groupId != null) _expandedGroupIds.add(result.groupId!);
    _refreshMetadata();
    _showSnackBar(context, '목록을 추가했습니다.');
  }

  Future<void> _editFolder(Folder folder, List<Folder> folders) async {
    final result = await showDialog<_FolderFormResult>(
      context: context,
      builder: (_) => _FolderEditDialog(
        folder: folder,
        folders: folders,
        groups: _groups,
        isHidden: _isFolderHidden(folder.id),
      ),
    );
    if (result == null || !mounted) {
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
        groupId: result.groupId,
        sortOrder: result.parentFolderId == folder.parentFolderId
            ? folder.sortOrder
            : (folders.isEmpty
                      ? -1
                      : folders
                            .map((f) => f.sortOrder)
                            .reduce((a, b) => a > b ? a : b)) +
                  1,
        createdAt: folder.createdAt,
        updatedAt: now,
      ),
    );
    await _setFolderHidden(folder.id, result.isHidden);
    if (!mounted) {
      return;
    }
    if (result.groupId != null) _expandedGroupIds.add(result.groupId!);
    _refreshMetadata();
    _showSnackBar(context, '목록을 수정했습니다.');
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
    String confirmLabel = '삭제',
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
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}

class _MetadataTaskListScreen extends StatefulWidget {
  const _MetadataTaskListScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.tasks,
    required this.subTaskRepository,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onOpenTaskDetail,
    this.reloadTasks,
    this.taskFilter,
    this.availableTags = const [],
  });

  final List<Tag> availableTags;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Task> tasks;
  final SubTaskRepository subTaskRepository;
  final Future<void> Function(Task task) onToggleTask;
  final Future<void> Function(Task task) onDeleteTask;
  final Future<void> Function(Task task) onOpenTaskDetail;
  final Future<List<Task>> Function()? reloadTasks;
  final bool Function(Task task)? taskFilter;

  @override
  State<_MetadataTaskListScreen> createState() =>
      _MetadataTaskListScreenState();
}

class _MetadataTaskListScreenState extends State<_MetadataTaskListScreen> {
  late List<Task> _tasks;
  String? _selectedTagId;

  @override
  void initState() {
    super.initState();
    _tasks = widget.tasks;
  }

  Future<void> _reloadTasks() async {
    final reloadTasks = widget.reloadTasks;
    if (reloadTasks == null) {
      return;
    }
    final latestTasks = await reloadTasks();
    if (!mounted) {
      return;
    }
    final filter = widget.taskFilter;
    setState(() {
      _tasks = filter == null
          ? latestTasks
          : latestTasks.where(filter).toList(growable: false);
    });
  }

  Future<void> _openTaskDetail(Task task) async {
    await widget.onOpenTaskDetail(task);
    await _reloadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    await widget.onToggleTask(task);
    await _reloadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks.removeWhere((item) => item.id == task.id);
    });
    await widget.onDeleteTask(task);
  }

  @override
  Widget build(BuildContext context) {
    final sortedTasks =
        _tasks
            .where(
              (t) =>
                  _selectedTagId == null || t.tagIds.contains(_selectedTagId),
            )
            .toList()
          ..sort(_compareMetadataTasks);
    final incompleteTasks = sortedTasks
        .where((task) => task.status == TaskStatus.active)
        .toList(growable: false);
    final completedTasks = sortedTasks
        .where((task) => task.status == TaskStatus.completed)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subtitle,
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
              ],
            ),
            const SizedBox(height: 20),
            if (widget.availableTags.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedTagId,
                decoration: const InputDecoration(labelText: '이 목록에서 태그로 찾기'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('모든 태그'),
                  ),
                  for (final tag in widget.availableTags)
                    DropdownMenuItem(value: tag.id, child: Text(tag.name)),
                ],
                onChanged: (value) => setState(() => _selectedTagId = value),
              ),
              const SizedBox(height: 20),
            ],
            if (sortedTasks.isEmpty)
              const _EmptyBlock(message: '작업 없음')
            else ...[
              _ListSectionHeader(title: '미완료', count: incompleteTasks.length),
              const SizedBox(height: 10),
              if (incompleteTasks.isEmpty)
                const _EmptyBlock(message: '미완료 작업이 없습니다.')
              else
                _MetadataTaskCard(
                  tasks: incompleteTasks,
                  subTaskRepository: widget.subTaskRepository,
                  onToggleTask: _toggleTask,
                  onDeleteTask: _deleteTask,
                  onOpenTaskDetail: _openTaskDetail,
                ),
              const SizedBox(height: 20),
              _ListSectionHeader(title: '완료', count: completedTasks.length),
              const SizedBox(height: 10),
              if (completedTasks.isEmpty)
                const _EmptyBlock(message: '완료된 작업이 없습니다.')
              else
                _MetadataTaskCard(
                  tasks: completedTasks,
                  subTaskRepository: widget.subTaskRepository,
                  onToggleTask: _toggleTask,
                  onDeleteTask: _deleteTask,
                  onOpenTaskDetail: _openTaskDetail,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetadataTaskCard extends StatelessWidget {
  const _MetadataTaskCard({
    required this.tasks,
    required this.subTaskRepository,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onOpenTaskDetail,
  });

  final List<Task> tasks;
  final SubTaskRepository subTaskRepository;
  final Future<void> Function(Task task) onToggleTask;
  final Future<void> Function(Task task) onDeleteTask;
  final Future<void> Function(Task task) onOpenTaskDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: _taskListCardShape,
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            Dismissible(
              key: ValueKey('metadata_dismiss_${tasks[i].id}'),
              direction: DismissDirection.horizontal,
              background: const _TaskSwipeBackground(
                action: _TaskSwipeAction.edit,
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const _TaskSwipeBackground(
                action: _TaskSwipeAction.delete,
                alignment: Alignment.centerRight,
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await onOpenTaskDetail(tasks[i]);
                  return false;
                }
                return true;
              },
              onDismissed: (_) => onDeleteTask(tasks[i]),
              child: _TaskListTile(
                task: tasks[i],
                onToggle: () => onToggleTask(tasks[i]),
                onOpenDetail: () => onOpenTaskDetail(tasks[i]),
                subTaskRepository: subTaskRepository,
                metadata: const _TaskMetadataLookup.empty(),
                showMetadata: false,
              ),
            ),
            if (i != tasks.length - 1) const Divider(height: 1),
          ],
        ],
      ),
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

class _TaskListTile extends StatefulWidget {
  const _TaskListTile({
    required this.task,
    required this.onToggle,
    required this.onOpenDetail,
    required this.subTaskRepository,
    required this.metadata,
    this.showMetadata = true,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetail;
  final SubTaskRepository subTaskRepository;
  final _TaskMetadataLookup metadata;
  final bool showMetadata;

  @override
  State<_TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<_TaskListTile> {
  var _isExpanded = false;
  late Future<List<SubTask>> _subTasksFuture;

  @override
  void initState() {
    super.initState();
    _subTasksFuture = widget.subTaskRepository.getSubTasks(widget.task.id);
  }

  @override
  void didUpdateWidget(_TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _isExpanded = false;
    }
    _subTasksFuture = widget.subTaskRepository.getSubTasks(widget.task.id);
  }

  void _reloadSubTasks() {
    setState(() {
      _subTasksFuture = widget.subTaskRepository.getSubTasks(widget.task.id);
    });
  }

  Future<void> _toggleSubTask(SubTask subTask) async {
    await widget.subTaskRepository.updateSubTaskDone(
      subTask.id,
      !subTask.isDone,
    );
    if (!mounted) {
      return;
    }
    _reloadSubTasks();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.dueDate != null && _isOverdue(task.dueDate!);
    final accentColor = _taskAccentColor(task, isOverdue: isOverdue);

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Stack(
        children: [
          if (!isCompleted && accentColor != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 4, color: accentColor),
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
                    _StatusCheckbox(task: task, onTap: widget.onToggle),
                    if (!isCompleted && task.dueDate != null) ...[
                      const SizedBox(height: 10),
                      _DueBadge(dueDate: task.dueDate!),
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
                        ],
                      ),
                      if (!isCompleted && widget.showMetadata) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: _TaskMetaStrip(
                            task: task,
                            metadata: widget.metadata,
                          ),
                        ),
                      ],
                      if (_isExpanded) ...[
                        const SizedBox(height: 10),
                        _SubTaskListPreview(
                          future: _subTasksFuture,
                          onToggle: _toggleSubTask,
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

class _SubTaskListPreview extends StatelessWidget {
  const _SubTaskListPreview({required this.future, required this.onToggle});

  final Future<List<SubTask>> future;
  final Future<void> Function(SubTask subTask) onToggle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SubTask>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final subTasks = snapshot.data ?? const <SubTask>[];
        if (subTasks.isEmpty) {
          return const _SubTaskEmptyPreview();
        }

        return Column(
          children: [
            for (final subTask in subTasks)
              _SubTaskPreviewRow(
                subTask: subTask,
                onToggle: () => onToggle(subTask),
              ),
          ],
        );
      },
    );
  }
}

class _SubTaskPreviewRow extends StatelessWidget {
  const _SubTaskPreviewRow({required this.subTask, required this.onToggle});

  final SubTask subTask;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Row(
          children: [
            Checkbox(
              value: subTask.isDone,
              onChanged: (_) => onToggle(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                subTask.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subTask.isDone ? AppTheme.muted : AppTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  decoration: subTask.isDone
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTaskEmptyPreview extends StatelessWidget {
  const _SubTaskEmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
      ),
      child: const Text(
        '서브 작업이 없습니다.',
        style: TextStyle(
          color: AppTheme.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _TaskSwipeAction { edit, delete }

class _TaskSwipeBackground extends StatelessWidget {
  const _TaskSwipeBackground({required this.action, required this.alignment});

  final _TaskSwipeAction action;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    final isDelete = action == _TaskSwipeAction.delete;
    final color = isDelete ? AppTheme.dangerRed : AppTheme.primaryBlue;
    final icon = isDelete ? Icons.delete_outline_rounded : Icons.edit_outlined;
    return Container(
      color: color.withValues(alpha: 0.1),
      alignment: alignment,
      padding: EdgeInsets.only(left: isLeft ? 20 : 0, right: isLeft ? 0 : 20),
      child: Icon(icon, color: color),
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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (metadata.tagsFor(task).isNotEmpty)
          metadata_picker.TaskMetadataChips(
            tags: metadata.tagsFor(task),
            folders: const [],
          ),
      ],
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

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.muted;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 34),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          _compactDueLabel(dueDate),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

Color? _taskAccentColor(Task task, {required bool isOverdue}) {
  if (isOverdue) {
    return AppTheme.dangerRed;
  }
  return switch (task.priority) {
    TaskPriority.high => AppTheme.dangerRed,
    TaskPriority.medium => AppTheme.warningOrange,
    TaskPriority.low => AppTheme.primaryBlue,
    null => null,
  };
}

const _taskListCardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
  side: BorderSide(color: AppTheme.line),
);

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
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.depth = 0,
    this.dragItem,
    this.onAccept,
    this.onTap,
    this.onEdit,
    this.editTooltip,
    this.expanded,
    this.canAccept,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;
  final int depth;
  final _MetadataDragItem? dragItem;
  final ValueChanged<_MetadataDragItem>? onAccept;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String? editTooltip;
  final bool? expanded;
  final bool Function(_MetadataDragItem)? canAccept;

  @override
  Widget build(BuildContext context) {
    final baseRow = ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.only(left: 16 + depth * 20, right: 8),
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: expanded != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) Text(trailing!),
                Icon(
                  expanded!
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: editTooltip ?? '편집',
                  ),
              ],
            )
          : onEdit != null
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
    Widget row = baseRow;
    final accept = onAccept;
    if (accept != null) {
      row = DragTarget<_MetadataDragItem>(
        onWillAcceptWithDetails: (details) =>
            canAccept?.call(details.data) ?? (details.data != dragItem),
        onAcceptWithDetails: (details) => accept(details.data),
        builder: (context, candidateData, rejectedData) {
          return Material(
            color: candidateData.isEmpty
                ? Colors.transparent
                : AppTheme.primaryBlue.withValues(alpha: 0.08),
            child: baseRow,
          );
        },
      );
    }
    final item = dragItem;
    if (item == null) {
      return row;
    }
    return LongPressDraggable<_MetadataDragItem>(
      data: item,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: baseRow,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: row),
      child: row,
    );
  }
}

class _MetadataRootDropTarget extends StatelessWidget {
  const _MetadataRootDropTarget({
    super.key,
    required this.onAccept,
    required this.child,
  });

  final ValueChanged<_MetadataDragItem> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_MetadataDragItem>(
      onWillAcceptWithDetails: (details) =>
          details.data.type == _MetadataDragType.folder &&
          details.data.id != inboxListId,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Material(
          color: candidateData.isEmpty
              ? Colors.transparent
              : AppTheme.primaryBlue.withValues(alpha: 0.06),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 12),
            child: child,
          ),
        );
      },
    );
  }
}

enum _MetadataDragType { tag, folder }

class _MetadataDragItem {
  const _MetadataDragItem._({required this.type, required this.id});

  const _MetadataDragItem.tag(String id)
    : this._(type: _MetadataDragType.tag, id: id);

  const _MetadataDragItem.folder(String id)
    : this._(type: _MetadataDragType.folder, id: id);

  final _MetadataDragType type;
  final String id;
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
  const _TagEditDialog({
    required this.folders,
    this.tag,
    this.selectedFolderId,
    this.isHidden = false,
  });

  final Tag? tag;
  final List<Folder> folders;
  final String? selectedFolderId;
  final bool isHidden;

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late bool _isHidden;
  String? _selectedFolderId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _colorController = TextEditingController(
      text: _normalizeHex(widget.tag?.color ?? '#3B82F6'),
    );
    _isHidden = widget.isHidden;
    _selectedFolderId = widget.selectedFolderId;
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
            if (widget.tag != null) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('숨김'),
                value: _isHidden,
                onChanged: (value) {
                  setState(() {
                    _isHidden = value;
                  });
                },
              ),
            ],
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
    Navigator.of(context).pop(
      _TagFormResult(
        name: name,
        color: color,
        folderId: _selectedFolderId,
        isHidden: _isHidden,
      ),
    );
  }
}

class _FolderGroupDialog extends StatefulWidget {
  const _FolderGroupDialog({this.group});
  final FolderGroup? group;
  @override
  State<_FolderGroupDialog> createState() => _FolderGroupDialogState();
}

class _FolderGroupDialogState extends State<_FolderGroupDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name ?? '',
  );
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.group == null ? '상위 폴더 추가' : '상위 폴더 수정'),
    content: TextField(
      controller: _name,
      decoration: const InputDecoration(labelText: '폴더 이름'),
    ),
    actions: [
      if (widget.group != null)
        TextButton(
          onPressed: () => Navigator.pop(context, ('', true)),
          child: const Text('폴더 삭제'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (_name.text.trim().isNotEmpty) {
            Navigator.pop(context, (_name.text.trim(), false));
          }
        },
        child: const Text('저장'),
      ),
    ],
  );
}

class _FolderEditDialog extends StatefulWidget {
  const _FolderEditDialog({
    required this.folders,
    this.folder,
    this.isHidden = false,
    this.groups = const [],
    this.initialGroupId,
  });

  final Folder? folder;
  final List<Folder> folders;
  final bool isHidden;
  final List<FolderGroup> groups;
  final String? initialGroupId;

  @override
  State<_FolderEditDialog> createState() => _FolderEditDialogState();
}

class _FolderEditDialogState extends State<_FolderEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late bool _isHidden;
  String? _parentFolderId;
  String? _groupId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    _colorController = TextEditingController(
      text: _normalizeHex(widget.folder?.color ?? '#22C55E'),
    );
    _parentFolderId = null;
    _groupId = widget.folder?.groupId ?? widget.initialGroupId;
    _isHidden = widget.isHidden;
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
    final isInbox = widget.folder?.id == inboxListId;
    return AlertDialog(
      title: Text(widget.folder == null ? '목록 추가' : '목록 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              enabled: !isInbox,
              decoration: const InputDecoration(labelText: '목록 이름'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _groupId ?? '',
              decoration: const InputDecoration(labelText: '상위 폴더'),
              items: [
                const DropdownMenuItem(value: '', child: Text('폴더 밖')),
                for (final group in widget.groups)
                  DropdownMenuItem(value: group.id, child: Text(group.name)),
              ],
              onChanged: isInbox
                  ? null
                  : (value) =>
                        setState(() => _groupId = value == '' ? null : value),
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
                    Icons.square_rounded,
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
            if (widget.folder != null && !isInbox) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('숨김'),
                value: _isHidden,
                onChanged: (value) {
                  setState(() {
                    _isHidden = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
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
        groupId: _groupId,
        isHidden: _isHidden,
      ),
    );
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
  const _TagFormResult({
    required this.name,
    required this.color,
    this.folderId,
    this.isHidden = false,
  }) : deleteRequested = false;

  const _TagFormResult.delete()
    : name = '',
      color = '',
      folderId = null,
      isHidden = false,
      deleteRequested = true;

  final String name;
  final String color;
  final String? folderId;
  final bool isHidden;
  final bool deleteRequested;
}

class _FolderFormResult {
  const _FolderFormResult({
    required this.name,
    required this.color,
    this.parentFolderId,
    this.groupId,
    this.isHidden = false,
  });
  final String name;
  final String color;
  final String? parentFolderId;
  final String? groupId;
  final bool isHidden;
}

bool _isDueToday(Task task) => isTaskDueToday(task, now: DateTime.now());

bool _isOverdue(DateTime dueDate) {
  return isDueDateOverdue(dueDate, now: DateTime.now());
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

const _metadataColorOptions = [
  '#EF4444',
  '#F97316',
  '#EAB308',
  '#22C55E',
  '#3B82F6',
  '#8B5CF6',
  '#6B7280',
];

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
  final days = _dueDays(date);
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

int _dueDays(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(date.year, date.month, date.day);
  return dueDay.difference(today).inDays;
}

String _compactDueLabel(DateTime date) {
  final days = _dueDays(date);
  if (days == 0) {
    return 'D-day';
  }
  if (days > 0) {
    return 'D-$days';
  }
  return 'D+${days.abs()}';
}

String _shortDateLabel(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

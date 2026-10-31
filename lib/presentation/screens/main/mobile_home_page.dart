import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/list_defaults.dart';
import '../../../data/models/home_view_options.dart';
import '../../../data/models/task_models.dart';
import '../../../data/models/task_swipe_options.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/home_task_summary.dart';
import '../../widgets/task_metadata_picker.dart' show colorFromHex;

enum _ScopeKind { all, list, tag, completed, trash }

enum _Period { today, week, month, all, custom }

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.settings,
    required this.settingsReady,
    required this.settingsRepository,
    required this.tags,
    required this.lists,
    required this.groups,
    required this.onSettingsSaved,
    required this.onRefresh,
    required this.onImport,
    required this.onSettings,
    required this.onAddFolder,
    required this.onAddList,
    required this.onAddTag,
    required this.onEditFolder,
    required this.onAddListToFolder,
    required this.onEditList,
    required this.onAddTaskToList,
    required this.onEditTag,
    required this.onAddTaskWithTag,

    required this.onOpenTask,
    required this.onToggleTask,
    required this.onRestoreTask,
    required this.onDeletePermanently,
    required this.onDeleteTask,
  });

  final List<Task> tasks;
  final bool isLoading;
  final AppSettings settings;
  final bool settingsReady;
  final SettingsRepository settingsRepository;
  final List<Tag> tags;
  final List<Folder> lists;
  final List<FolderGroup> groups;
  final ValueChanged<AppSettings> onSettingsSaved;
  final VoidCallback onRefresh, onSettings;
  final Future<void> Function()? onAddFolder;
  final Future<void> Function() onAddList, onAddTag;
  final Future<void> Function(FolderGroup) onEditFolder, onAddListToFolder;
  final Future<void> Function(Folder) onEditList, onAddTaskToList;
  final Future<void> Function(Tag) onEditTag, onAddTaskWithTag;
  final Future<void> Function() onImport;
  final Future<void> Function(Task) onOpenTask,
      onToggleTask,
      onRestoreTask,
      onDeletePermanently,
      onDeleteTask;

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _ScopeKind _scope = _ScopeKind.all;
  String? _scopeId;
  _Period _period = _Period.today;
  DateTimeRange? _customRange;
  HomeViewOptions _view = const HomeViewOptions();
  bool _loadedPreferences = false;
  final Set<String> _expandedFolderIds = {};
  final Set<String> _swipingTaskIds = {};
  double _drawerDragDistance = 0;

  String get _scopeLabel => switch (_scope) {
    _ScopeKind.all => '전체',
    _ScopeKind.list =>
      widget.lists.where((l) => l.id == _scopeId).firstOrNull?.name ??
          inboxListName,
    _ScopeKind.tag =>
      '#${widget.tags.where((t) => t.id == _scopeId).firstOrNull?.name ?? '태그'}',
    _ScopeKind.completed => '완료',
    _ScopeKind.trash => '휴지통',
  };

  (DateTime, DateTime) _range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      _Period.today => (
        today,
        DateTime(today.year, today.month, today.day + 1),
      ),
      _Period.week => (
        DateTime(today.year, today.month, today.day - today.weekday + 1),
        DateTime(today.year, today.month, today.day - today.weekday + 8),
      ),
      _Period.month => (
        DateTime(today.year, today.month),
        DateTime(today.year, today.month + 1),
      ),
      _Period.all => (DateTime(1), DateTime(10000)),
      _Period.custom => (
        _customRange!.start,
        DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day + 1,
        ),
      ),
    };
  }

  String get _periodLabel => switch (_period) {
    _Period.today => '오늘',
    _Period.week => '이번 주',
    _Period.month => '이번 달',
    _Period.all => '전체',
    _Period.custom =>
      _customRange!.start == _customRange!.end
          ? DateFormat('yyyy년 M월 d일', 'ko_KR').format(_customRange!.start)
          : '${DateFormat('yyyy.MM.dd').format(_customRange!.start)} ~ ${DateFormat(_customRange!.start.year == _customRange!.end.year ? 'MM.dd' : 'yyyy.MM.dd').format(_customRange!.end)}',
  };

  void _selectScope(_ScopeKind scope, [String? id]) {
    setState(() {
      _scope = scope;
      _scopeId = id;
    });
    Navigator.of(context).pop();
  }

  Widget _drawerEntry(
    String label,
    IconData icon,
    _ScopeKind kind, [
    String? id,
    Color? color,
  ]) {
    return ListTile(
      key: ValueKey('scope-${kind.name}-${id ?? ''}'),
      selected: _scope == kind && _scopeId == id,
      selectedTileColor: AppTheme.primaryBlue.withValues(alpha: .08),
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () => _selectScope(kind, id),
      onLongPress: switch (kind) {
        _ScopeKind.list => () {
          final list = widget.lists.where((l) => l.id == id).firstOrNull;
          if (list != null) {
            _metadataActions(
              list.name,
              editLabel: '목록 편집',
              addLabel: '할 일 추가',
              onEdit: () => widget.onEditList(list),
              onAdd: () => widget.onAddTaskToList(list),
            );
          }
        },
        _ScopeKind.tag => () {
          final tag = widget.tags.where((t) => t.id == id).firstOrNull;
          if (tag != null) {
            _metadataActions(
              tag.name,
              editLabel: '태그 편집',
              addLabel: '할 일 추가',
              onEdit: () => widget.onEditTag(tag),
              onAdd: () => widget.onAddTaskWithTag(tag),
            );
          }
        },
        _ => null,
      },
    );
  }

  Future<void> _metadataActions(
    String title, {
    required String editLabel,
    required String addLabel,
    required Future<void> Function() onEdit,
    required Future<void> Function() onAdd,
  }) async {
    final edit = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(editLabel),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(addLabel),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (edit == null || !mounted) return;
    if (edit) {
      await onEdit();
    } else {
      await onAdd();
    }
  }

  Future<void> _manageVisibility() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DrawerVisibilitySheet(
      lists: widget.lists,
      tags: widget.tags,
      groups: widget.groups,
      settings: widget.settings,
      repository: widget.settingsRepository,
      onSaved: (saved) {
        if (mounted) widget.onSettingsSaved(saved);
      },
    ),
  );

  Widget _drawerHeading(String text, {List<Widget> actions = const []}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ),
            ...actions,
          ],
        ),
      );

  List<Folder> get _drawerLists => widget.lists
      .where(
        (list) =>
            list.id == inboxListId ||
            !widget.settings.hiddenFolderIds.contains(list.id),
      )
      .toList();
  List<Tag> get _drawerTags => widget.tags
      .where((tag) => !widget.settings.hiddenTagIds.contains(tag.id))
      .toList();

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'KUTODO',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: Material(
                type: MaterialType.transparency,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerEntry(
                      _period == _Period.all ? '전체' : _periodLabel,
                      Icons.format_list_bulleted_rounded,
                      _ScopeKind.all,
                    ),
                    _drawerEntry(
                      inboxListName,
                      Icons.square_rounded,
                      _ScopeKind.list,
                      inboxListId,
                      colorFromHex(
                        widget.lists
                            .where((l) => l.id == inboxListId)
                            .firstOrNull
                            ?.color,
                        fallback: AppTheme.successGreen,
                      ),
                    ),
                    _drawerHeading(
                      '목록',
                      actions: [
                        IconButton(
                          tooltip: '숨김 관리',
                          icon: const Icon(Icons.visibility_off_outlined),
                          onPressed: widget.settingsReady
                              ? _manageVisibility
                              : null,
                        ),
                        IconButton(
                          tooltip: '폴더 추가',
                          icon: const Icon(Icons.create_new_folder_outlined),
                          onPressed: widget.onAddFolder,
                        ),
                        IconButton(
                          tooltip: '목록 추가',
                          icon: const Icon(Icons.add_box_outlined),
                          onPressed: widget.onAddList,
                        ),
                      ],
                    ),
                    if (widget.groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          '등록된 폴더가 없습니다.',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ),
                    for (final group in widget.groups)
                      GestureDetector(
                        onLongPress: () => _metadataActions(
                          group.name,
                          editLabel: '폴더 편집',
                          addLabel: '목록 추가',
                          onEdit: () => widget.onEditFolder(group),
                          onAdd: () => widget.onAddListToFolder(group),
                        ),
                        child: ExpansionTile(
                          key: ValueKey('drawer-folder-${group.id}'),
                          initiallyExpanded: _expandedFolderIds.contains(
                            group.id,
                          ),
                          onExpansionChanged: (expanded) => setState(() {
                            if (expanded) {
                              _expandedFolderIds.add(group.id);
                            } else {
                              _expandedFolderIds.remove(group.id);
                            }
                          }),
                          leading: const Icon(Icons.folder_rounded),
                          title: Text(group.name),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          childrenPadding: const EdgeInsets.only(left: 18),
                          children: [
                            for (final list in _drawerLists.where(
                              (l) => l.groupId == group.id,
                            ))
                              _drawerEntry(
                                list.name,
                                Icons.square_rounded,
                                _ScopeKind.list,
                                list.id,
                                colorFromHex(
                                  list.color,
                                  fallback: AppTheme.successGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                    for (final list in _drawerLists.where(
                      (l) => l.groupId == null && l.id != inboxListId,
                    ))
                      _drawerEntry(
                        list.name,
                        Icons.square_rounded,
                        _ScopeKind.list,
                        list.id,
                        colorFromHex(
                          list.color,
                          fallback: AppTheme.successGreen,
                        ),
                      ),
                    _drawerHeading(
                      '태그',
                      actions: [
                        IconButton(
                          tooltip: '태그 추가',
                          icon: const Icon(Icons.new_label_outlined),
                          onPressed: widget.onAddTag,
                        ),
                      ],
                    ),
                    if (_drawerTags.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          '등록된 태그가 없습니다.',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ),
                    for (final tag in _drawerTags)
                      _drawerEntry(
                        tag.name,
                        Icons.tag_rounded,
                        _ScopeKind.tag,
                        tag.id,
                        colorFromHex(tag.color),
                      ),
                    _drawerHeading('기타'),
                    _drawerEntry(
                      '완료',
                      Icons.check_box_outlined,
                      _ScopeKind.completed,
                    ),
                    _drawerEntry(
                      '휴지통',
                      Icons.delete_outline_rounded,
                      _ScopeKind.trash,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: const ValueKey('drawer-settings'),
            leading: const Icon(Icons.settings_outlined),
            title: const Text('설정'),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSettings();
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _pickPeriod() async {
    final selected = await showModalBottomSheet<_Period>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '날짜 / 기간 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final period in _Period.values)
              ListTile(
                title: Text(switch (period) {
                  _Period.today => '오늘',
                  _Period.week => '이번 주',
                  _Period.month => '이번 달',
                  _Period.all => '전체',
                  _Period.custom => '기간 선택',
                }),
                trailing: _period == period
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, period),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == _Period.custom) {
      final isRange = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '기간 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('단일 날짜'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('날짜 구간'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
      if (isRange == null || !mounted) return;
      DateTimeRange? range;
      if (isRange) {
        range = await showDateRangePicker(
          context: context,
          initialDateRange: _customRange,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100, 12, 31),
          helpText: '기간 선택',
          saveText: '적용',
          confirmText: '적용',
          cancelText: '취소',
          fieldStartLabelText: '시작일',
          fieldEndLabelText: '종료일',
        );
      } else {
        final date = await showDatePicker(
          context: context,
          initialDate: _customRange?.start ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100, 12, 31),
          helpText: '단일 날짜 선택',
          fieldLabelText: '연 / 월 / 일',
        );
        if (date != null) range = DateTimeRange(start: date, end: date);
      }
      if (range == null || !mounted) return;
      setState(() {
        _customRange = range;
        _period = selected;
      });
    } else {
      setState(() {
        _period = selected;
      });
    }
  }

  Future<void> _adjustView() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ViewOptionsSheet(
        initial: _view,
        tags: widget.tags,
        isTrash: _scope == _ScopeKind.trash,
        onChanged: (value) => setState(() => _view = value),
        onSave: (value) async {
          final latest = await widget.settingsRepository.getSettings();
          final saved = await widget.settingsRepository.saveSettings(
            latest.copyWith(homeView: value),
          );
          if (mounted) widget.onSettingsSaved(saved);
        },
      ),
    );
  }

  bool _matches(Task task) {
    final scopeMatches = switch (_scope) {
      _ScopeKind.all => true,
      _ScopeKind.list => task.listId == _scopeId,
      _ScopeKind.tag => task.tagIds.contains(_scopeId),
      _ScopeKind.completed => task.status == TaskStatus.completed,
      _ScopeKind.trash => task.status == TaskStatus.deleted,
    };
    if (!scopeMatches || task.status == TaskStatus.excluded) return false;
    if (_scope != _ScopeKind.trash &&
        (task.status == TaskStatus.deleted ||
            !_view.statuses.contains(task.status))) {
      return false;
    }
    return (_view.priorities.isEmpty ||
            _view.priorities.contains(task.priority)) &&
        (_view.tagIds.isEmpty || task.tagIds.any(_view.tagIds.contains));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedPreferences && widget.settingsReady) {
      _view = widget.settings.homeView;
      _loadedPreferences = true;
    }
    final now = DateTime.now();
    final (start, end) = _range(now);
    bool inRange(DateTime? date) =>
        date != null &&
        !date.toLocal().isBefore(start) &&
        date.toLocal().isBefore(end);
    final matching = widget.tasks.where(_matches).toList()
      ..sort((a, b) => _compare(a, b, _view.sort));
    final active = matching
        .where((t) => t.status == TaskStatus.active)
        .toList();
    final periodTasks = active
        .where((t) => t.dueDate == null || inRange(t.dueDate))
        .toList();
    final urgent = active
        .where(
          (t) => isTaskUrgent(t, now: now, days: widget.settings.urgentDueDays),
        )
        .toList();
    final overdue = active.where((t) => isTaskOverdue(t, now: now)).toList();
    final completed = matching
        .where(
          (t) =>
              t.status == TaskStatus.completed &&
              inRange(t.completedAt ?? t.dueDate ?? t.updatedAt),
        )
        .toList();
    final trash = matching
        .where((t) => inRange(t.deletedAt ?? t.dueDate ?? t.updatedAt))
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _drawer(),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: '사이드 메뉴',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: InkWell(
          key: const ValueKey('home-period'),
          onTap: _pickPeriod,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scopeLabel,
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _period == _Period.today
                            ? '오늘 · ${DateFormat('M월 d일', 'ko_KR').format(now)}'
                            : _periodLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'eCampus 가져오기',
            onPressed: widget.onImport,
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: '보기 조정',
            onPressed: widget.settingsReady ? _adjustView : null,
            icon: Badge(
              isLabelVisible: !_view.isDefault,
              smallSize: 6,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GestureDetector(
          // Child row gestures win on Tasks; blank space still opens the Drawer.
          onHorizontalDragStart: (_) => _drawerDragDistance = 0,
          onHorizontalDragUpdate: (details) =>
              _drawerDragDistance += details.primaryDelta!,
          onHorizontalDragCancel: () => _drawerDragDistance = 0,
          onHorizontalDragEnd: (details) {
            if ((_drawerDragDistance > 80 ||
                    (_drawerDragDistance > 20 &&
                        (details.primaryVelocity ?? 0) > 500))) {
              _scaffoldKey.currentState?.openDrawer();
            }
            _drawerDragDistance = 0;
          },
        child: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_scope == _ScopeKind.trash)
              _section('휴지통', 'trash', trash)
            else ...[
              if (_scope != _ScopeKind.completed) ...[
                _section(_periodLabel, 'period', periodTasks),
                _section('마감 임박', 'urgent', urgent),
                _section('마감 지남', 'overdue', overdue),
              ],
              _section('완료', 'completed', completed),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _section(String title, String id, List<Task> tasks) => Padding(
    key: ValueKey('home-section-$id'),
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                ),
              ),
              Text(
                '${tasks.length}',
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Text(
              '표시할 할 일이 없습니다.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ),
        for (final task in tasks) _taskRow(task, id),
      ],
    ),
  );

  Widget _taskRow(Task task, String section) {
    final list = widget.lists.where((l) => l.id == task.listId).firstOrNull;
    final group = widget.groups.where((g) => g.id == list?.groupId).firstOrNull;
    final path = [
      if (group != null) group.name,
      if (list != null) list.name,
    ].join(' > ');
    final details = [
      if (path.isNotEmpty) path,
      for (final tag in widget.tags.where((t) => task.tagIds.contains(t.id)))
        '#${tag.name}',
    ];
    final due = task.dueDate?.toLocal();
    final dueText = due == null
        ? '마감 없음'
        : DateFormat(
            due.year == DateTime.now().year &&
                    due.month == DateTime.now().month &&
                    due.day == DateTime.now().day
                ? 'HH:mm'
                : 'M/d HH:mm',
            'ko_KR',
          ).format(due);
    return Dismissible(
      key: ValueKey('task-swipe-$section-${task.id}'),
      direction: widget.settingsReady ? DismissDirection.horizontal : DismissDirection.none,
      background: _swipeBackground(
        task,
        toRight: Directionality.of(context) == TextDirection.ltr,
      ),
      secondaryBackground: _swipeBackground(
        task,
        toRight: Directionality.of(context) != TextDirection.ltr,
      ),
      confirmDismiss: (direction) async {
        final toRight =
            direction ==
            (Directionality.of(context) == TextDirection.ltr
                ? DismissDirection.startToEnd
                : DismissDirection.endToStart);
        await _applySwipe(
          task,
          widget.settings.taskSwipes.action(
            toRight: toRight,
            inTrash: task.status == TaskStatus.deleted,
          ),
        );
        // Repositories own removal/state changes; never dismiss optimistically.
        return false;
      },
      child: ListTile(
        key: ValueKey('home-task-$section-${task.id}'),
        contentPadding: EdgeInsets.zero,
        onTap: () => widget.onOpenTask(task),
      leading: task.status == TaskStatus.deleted
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.delete_outline_rounded),
            )
          : Checkbox(
              value: task.status == TaskStatus.completed,
              onChanged: (_) => widget.onToggleTask(task),
            ),
        title: Text(
          task.title,
          softWrap: true,
          style: TextStyle(
            fontSize: 13,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: details.isEmpty
            ? null
            : Text(
                details.join(' · '),
                softWrap: true,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
        trailing: task.status == TaskStatus.deleted
            ? PopupMenuButton<String>(
                tooltip: '휴지통 작업 메뉴',
                onSelected: (value) async {
                  if (value == 'restore') {
                    await widget.onRestoreTask(task);
                    return;
                  }
                  await _confirmPermanentDelete(task);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'restore', child: Text('복원')),
                  PopupMenuItem(value: 'delete', child: Text('영구 삭제')),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dueText,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          task.status == TaskStatus.active &&
                              due != null &&
                              isDueDateOverdue(due, now: DateTime.now())
                          ? AppTheme.dangerRed
                          : AppTheme.muted,
                    ),
                  ),
                  if (task.priority != null)
                    Text(
                      switch (task.priority!) {
                        TaskPriority.high => '높음',
                        TaskPriority.medium => '중간',
                        TaskPriority.low => '낮음',
                      },
                      style: TextStyle(
                        fontSize: 10,
                        color: task.priority == TaskPriority.high
                            ? AppTheme.warningOrange
                            : AppTheme.muted,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _swipeBackground(Task task, {required bool toRight}) {
    final action = widget.settings.taskSwipes.action(
      toRight: toRight,
      inTrash: task.status == TaskStatus.deleted,
    );
    final destructive =
        action == TaskSwipeAction.delete ||
        action == TaskSwipeAction.deletePermanently;
    final color = destructive ? AppTheme.dangerRed : AppTheme.primaryBlue;
    return Container(
      color: color.withValues(alpha: .1),
      alignment: toRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(switch (action) {
            TaskSwipeAction.complete => Icons.check_box_outlined,
            TaskSwipeAction.edit => Icons.edit_outlined,
            TaskSwipeAction.delete => Icons.delete_outline_rounded,
            TaskSwipeAction.restore => Icons.restore_rounded,
            TaskSwipeAction.deletePermanently => Icons.delete_forever_rounded,
          }, color: color),
          const SizedBox(width: 8),
          Text(
            action == TaskSwipeAction.complete
                ? (task.status == TaskStatus.completed ? '미완료로' : '완료')
                : action.label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _applySwipe(Task task, TaskSwipeAction action) async {
    if (!_swipingTaskIds.add(task.id)) return;
    try {
      switch (action) {
        case TaskSwipeAction.complete:
          await widget.onToggleTask(task);
        case TaskSwipeAction.edit:
          await widget.onOpenTask(task);
        case TaskSwipeAction.delete:
          await widget.onDeleteTask(task);
        case TaskSwipeAction.restore:
          await widget.onRestoreTask(task);
        case TaskSwipeAction.deletePermanently:
          await _confirmPermanentDelete(task);
      }
    } catch (_) {
      if (mounted) {
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('스와이프 작업 처리 중 오류가 발생했습니다. 목록을 새로고침해 확인해주세요.'),
          ),
        );
      }
    } finally {
      _swipingTaskIds.remove(task.id);
    }
  }

  Future<void> _confirmPermanentDelete(Task task) async {
    if (await _confirmTrashDeletion() && mounted) {
      await widget.onDeletePermanently(task);
    }
  }

  Future<bool> _confirmTrashDeletion({int? selectedCount}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          selectedCount == null
              ? '영구 삭제할까요?'
              : '선택한 $selectedCount개를 영구 삭제할까요?',
        ),
        content: const Text('이 작업은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(selectedCount == null ? '영구 삭제' : '선택 삭제'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

int _compare(Task a, Task b, HomeSort sort) {
  int due(bool descending) {
    if (a.dueDate == null) return b.dueDate == null ? 0 : 1;
    if (b.dueDate == null) return -1;
    return descending
        ? b.dueDate!.compareTo(a.dueDate!)
        : a.dueDate!.compareTo(b.dueDate!);
  }

  final compared = switch (sort) {
    HomeSort.standard => a.sortOrder.compareTo(b.sortOrder),
    HomeSort.dueSoon => due(false),
    HomeSort.dueLate => due(true),
    HomeSort.newest => b.createdAt.compareTo(a.createdAt),
    HomeSort.priority => (a.priority?.index ?? 3).compareTo(
      b.priority?.index ?? 3,
    ),
  };
  if (compared != 0) return compared;
  final created = a.createdAt.compareTo(b.createdAt);
  return created == 0 ? a.id.compareTo(b.id) : created;
}

class _DrawerVisibilitySheet extends StatefulWidget {
  const _DrawerVisibilitySheet({
    required this.lists,
    required this.tags,
    required this.groups,
    required this.settings,
    required this.repository,
    required this.onSaved,
  });

  final List<Folder> lists;
  final List<Tag> tags;
  final List<FolderGroup> groups;
  final AppSettings settings;
  final SettingsRepository repository;
  final ValueChanged<AppSettings> onSaved;

  @override
  State<_DrawerVisibilitySheet> createState() => _DrawerVisibilitySheetState();
}

class _DrawerVisibilitySheetState extends State<_DrawerVisibilitySheet> {
  late AppSettings _settings = widget.settings;
  bool _saving = false;
  String? _error;

  Future<void> _setHidden(String id, bool hidden, {required bool isTag}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Merge only this visibility change into the latest saved settings.
      final latest = await widget.repository.getSettings();
      final ids = {...(isTag ? latest.hiddenTagIds : latest.hiddenFolderIds)};
      if (hidden) {
        ids.add(id);
      } else {
        ids.remove(id);
      }
      final saved = await widget.repository.saveSettings(
        isTag
            ? latest.copyWith(hiddenTagIds: ids)
            : latest.copyWith(hiddenFolderIds: ids),
      );
      widget.onSaved(saved);
      if (mounted) setState(() => _settings = saved);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '숨김 설정을 저장하지 못했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '숨김 관리',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const Text('숨긴 목록과 태그는 메뉴에서만 가려집니다.'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                const ListTile(title: Text('목록')),
                for (final list in widget.lists)
                  SwitchListTile.adaptive(
                    key: ValueKey('visibility-list-${list.id}'),
                    title: Text(list.name),
                    subtitle: Text(
                      list.id == inboxListId
                          ? '항상 표시'
                          : [
                              if (list.groupId != null)
                                widget.groups
                                        .where((g) => g.id == list.groupId)
                                        .firstOrNull
                                        ?.name ??
                                    '폴더',
                              _settings.hiddenFolderIds.contains(list.id)
                                  ? '숨김'
                                  : '표시',
                            ].join(' · '),
                    ),
                    value:
                        list.id != inboxListId &&
                        _settings.hiddenFolderIds.contains(list.id),
                    onChanged: _saving || list.id == inboxListId
                        ? null
                        : (hidden) => _setHidden(list.id, hidden, isTag: false),
                  ),
                const ListTile(title: Text('태그')),
                if (widget.tags.isEmpty)
                  const ListTile(title: Text('등록된 태그가 없습니다.')),
                for (final tag in widget.tags)
                  SwitchListTile.adaptive(
                    key: ValueKey('visibility-tag-${tag.id}'),
                    title: Text(tag.name),
                    subtitle: Text(
                      _settings.hiddenTagIds.contains(tag.id) ? '숨김' : '표시',
                    ),
                    value: _settings.hiddenTagIds.contains(tag.id),
                    onChanged: _saving
                        ? null
                        : (hidden) => _setHidden(tag.id, hidden, isTag: true),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    ),
  );
}

class _ViewOptionsSheet extends StatefulWidget {
  const _ViewOptionsSheet({
    required this.initial,
    required this.tags,
    required this.isTrash,
    required this.onChanged,
    required this.onSave,
  });
  final HomeViewOptions initial;
  final List<Tag> tags;
  final bool isTrash;
  final ValueChanged<HomeViewOptions> onChanged;
  final Future<void> Function(HomeViewOptions) onSave;
  @override
  State<_ViewOptionsSheet> createState() => _ViewOptionsSheetState();
}

class _ViewOptionsSheetState extends State<_ViewOptionsSheet> {
  late HomeViewOptions _value = widget.initial;
  bool _saving = false;
  void _change(HomeViewOptions value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  Set<T> _toggle<T>(Set<T> values, T value) => values.contains(value)
      ? ({...values}..remove(value))
      : ({...values}..add(value));

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '보기 조정',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '정렬',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final sort in HomeSort.values)
                        ChoiceChip(
                          label: Text(sort.label),
                          selected: _value.sort == sort,
                          onSelected: _saving
                              ? null
                              : (_) => _change(_value.copyWith(sort: sort)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '상태',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (widget.isTrash)
                    const Text(
                      '휴지통에서는 상태 필터를 적용하지 않습니다.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final status in [
                        TaskStatus.active,
                        TaskStatus.completed,
                      ])
                        FilterChip(
                          label: Text(
                            status == TaskStatus.active ? '미완료' : '완료',
                          ),
                          selected: _value.statuses.contains(status),
                          onSelected: _saving || widget.isTrash
                              ? null
                              : (_) => _change(
                                  _value.copyWith(
                                    statuses: _toggle(_value.statuses, status),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '우선순위',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    '선택하지 않으면 모든 우선순위를 표시합니다.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final priority in TaskPriority.values)
                        FilterChip(
                          label: Text(switch (priority) {
                            TaskPriority.high => '높음',
                            TaskPriority.medium => '중간',
                            TaskPriority.low => '낮음',
                          }),
                          selected: _value.priorities.contains(priority),
                          onSelected: _saving
                              ? null
                              : (_) => _change(
                                  _value.copyWith(
                                    priorities: _toggle(
                                      _value.priorities,
                                      priority,
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '태그',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    '선택한 태그 중 하나가 있는 작업을 표시합니다.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  if (widget.tags.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('등록된 태그가 없습니다.'),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in widget.tags)
                        FilterChip(
                          label: Text('#${tag.name}'),
                          selected: _value.tagIds.contains(tag.id),
                          avatar: Icon(
                            Icons.circle,
                            size: 10,
                            color: colorFromHex(tag.color),
                          ),
                          onSelected: _saving
                              ? null
                              : (_) => _change(
                                  _value.copyWith(
                                    tagIds: _toggle(_value.tagIds, tag.id),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => _change(const HomeViewOptions()),
                  child: const Text('기본값 초기화'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await widget.onSave(_value);
                            if (context.mounted) Navigator.pop(context);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '보기 설정을 저장하지 못했습니다. 다시 시도해주세요.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: Text(_saving ? '저장 중…' : '저장'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/list_defaults.dart';
import '../../../data/models/home_view_options.dart';
import '../../../data/models/home_period_preference.dart';
import '../../../data/models/task_models.dart';
import '../../../data/models/task_swipe_options.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/home_task_summary.dart';
import '../../widgets/task_metadata_picker.dart' show colorFromHex;
import 'drawer_context_item.dart';

enum _ScopeKind { period, all, list, tag, completed, trash }

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({
    super.key,
    required this.tasks,
    required this.isLoading,
    this.isActive = true,
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
    required this.onMoveList,
    required this.onMoveTag,
    required this.onOpenExcluded,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool isActive;
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
  final Future<void> Function(String id, String? groupId, String? beforeId)
  onMoveList;
  final Future<void> Function(String id, String? beforeId) onMoveTag;
  final Future<void> Function() onOpenExcluded;
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
  _ScopeKind _scope = _ScopeKind.period;
  String? _scopeId;
  HomePeriod _period = HomePeriod.today;
  DateTimeRange? _customRange;
  HomeViewOptions _view = const HomeViewOptions();
  HomeViewOptions _trashView = const HomeViewOptions();
  bool _trashSelectionMode = false;
  bool _trashBulkBusy = false;
  final Set<String> _selectedTrashIds = {};
  bool _loadedPreferences = false;
  bool _savingPeriod = false;
  HomePeriod _trashPeriod = HomePeriod.all;
  DateTimeRange? _trashCustomRange;
  final _dismissMenus = ValueNotifier<int>(0);
  final _drawerScroll = ScrollController();
  final _drawerScrollKey = GlobalKey();
  final Map<String, ExpansibleController> _folderControllers = {};
  Offset? _dragPosition;
  bool _dragMoving = false;
  bool _metadataBusy = false;
  Timer? _dragScrollTimer;
  double _scrollDelta = 0;
  final Set<String> _expandedFolderIds = {};
  final Set<String> _swipingTaskIds = {};
  double _drawerDragDistance = 0;

  void _resetTrashSession() {
    _trashView = const HomeViewOptions();
    _trashPeriod = HomePeriod.all;
    _trashCustomRange = null;
    _trashSelectionMode = false;
    _selectedTrashIds.clear();
  }

  @override
  void didUpdateWidget(covariant MobileHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) _resetTrashSession();
    _selectedTrashIds.retainAll(
      widget.tasks
          .where((t) => t.status == TaskStatus.deleted)
          .map((t) => t.id),
    );
  }

  String get _scopeLabel => switch (_scope) {
    _ScopeKind.period || _ScopeKind.all => '할 일',
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
    if (_scope == _ScopeKind.all) return (DateTime(1), DateTime(10000));
    final range = _scope == _ScopeKind.trash ? _trashCustomRange : _customRange;
    return switch (_scope == _ScopeKind.trash ? _trashPeriod : _period) {
      HomePeriod.today => (
        today,
        DateTime(today.year, today.month, today.day + 1),
      ),
      HomePeriod.week => (
        DateTime(today.year, today.month, today.day - today.weekday + 1),
        DateTime(today.year, today.month, today.day - today.weekday + 8),
      ),
      HomePeriod.month => (
        DateTime(today.year, today.month),
        DateTime(today.year, today.month + 1),
      ),
      HomePeriod.all => (DateTime(1), DateTime(10000)),
      HomePeriod.custom => (
        range!.start,
        DateTime(range.end.year, range.end.month, range.end.day + 1),
      ),
    };
  }

  String get _periodLabel {
    final mode = _scope == _ScopeKind.trash ? _trashPeriod : _period;
    final range = _scope == _ScopeKind.trash ? _trashCustomRange : _customRange;
    return switch (mode) {
      HomePeriod.today => '오늘',
      HomePeriod.week => '이번 주',
      HomePeriod.month => '이번 달',
      HomePeriod.all => '전체',
      HomePeriod.custom =>
        range!.start == range.end
            ? DateFormat('yyyy년 M월 d일', 'ko_KR').format(range.start)
            : '${DateFormat('yyyy.MM.dd').format(range.start)} ~ ${DateFormat(range.start.year == range.end.year ? 'MM.dd' : 'yyyy.MM.dd').format(range.end)}',
    };
  }

  String get _savedPeriodLabel {
    if (_period == HomePeriod.today) return '오늘';
    if (_period == HomePeriod.week) return '이번 주';
    if (_period == HomePeriod.month) return '이번 달';
    if (_period == HomePeriod.all) return '오늘';
    final range = _customRange!;
    return range.start == range.end
        ? DateFormat('yyyy년 M월 d일', 'ko_KR').format(range.start)
        : '${DateFormat('yyyy.MM.dd').format(range.start)} ~ ${DateFormat(range.start.year == range.end.year ? 'MM.dd' : 'yyyy.MM.dd').format(range.end)}';
  }

  void _selectScope(_ScopeKind scope, [String? id]) {
    if (_trashBulkBusy || _metadataBusy) return;
    _dismissMenus.value++;
    setState(() {
      if (_scope != scope || _scopeId != id || scope == _ScopeKind.trash) {
        _resetTrashSession();
      }
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
    final row = ListTile(
      key: ValueKey('scope-${kind.name}-${id ?? ''}'),
      selected: _scope == kind && _scopeId == id,
      selectedTileColor: AppTheme.primaryBlue.withValues(alpha: .08),
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () => _selectScope(kind, id),
    );
    if (kind != _ScopeKind.list && kind != _ScopeKind.tag) return row;
    final list = widget.lists.where((l) => l.id == id).firstOrNull;
    final tag = widget.tags.where((t) => t.id == id).firstOrNull;
    final isList = kind == _ScopeKind.list;
    final draggable = !isList || id != inboxListId;
    final item = DrawerDragItem(
      isList ? DrawerDragKind.list : DrawerDragKind.tag,
      id!,
    );
    final child = DrawerContextItem(
      key: ValueKey('drawer-item-${kind.name}-$id'),
      label: label,
      icon: icon,
      dismissMenus: _dismissMenus,
      dragItem: draggable && !_metadataBusy ? item : null,
      onDragChanged: _dragChanged,
      onDragPosition: _scrollDrag,
      actions: [
        DrawerContextAction(
          isList ? '목록 편집' : '태그 편집',
          Icons.edit_outlined,
          () => isList ? widget.onEditList(list!) : widget.onEditTag(tag!),
        ),
        DrawerContextAction(
          '할 일 추가',
          Icons.add_rounded,
          () => isList
              ? widget.onAddTaskToList(list!)
              : widget.onAddTaskWithTag(tag!),
        ),
      ],
      child: row,
    );
    return _dropTarget(
      key: 'drawer-drop-${kind.name}-$id',
      accept: (data) => data.kind == item.kind && data.id != id,
      onDrop: (data) => isList
          ? widget.onMoveList(
              data.id,
              list!.groupId,
              id == inboxListId ? null : id,
            )
          : widget.onMoveTag(data.id, id),
      onDropAt: (data, after) =>
          _dropRelativeTo(data, id, isList: isList, after: after),
      child: child,
    );
  }

  @override
  void dispose() {
    _dragScrollTimer?.cancel();
    _dismissMenus.dispose();
    _drawerScroll.dispose();
    for (final controller in _folderControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _dragChanged(DrawerDragItem? item, bool moving) {
    if (!mounted) return;
    setState(() {
      _dragMoving = moving;
    });
    if (item == null) {
      _dragScrollTimer?.cancel();
      _dragScrollTimer = null;
      _scrollDelta = 0;
    }
  }

  void _scrollDrag(Offset position) {
    _dragPosition = position;
    final box = _drawerScrollKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !_drawerScroll.hasClients) return;
    final y = box.globalToLocal(position).dy;
    _scrollDelta = y < 48
        ? -12
        : y > box.size.height - 48
        ? 12
        : 0;
    _dragScrollTimer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_drawerScroll.hasClients || _scrollDelta == 0) return;
      final position = _drawerScroll.position;
      _drawerScroll.jumpTo(
        (_drawerScroll.offset + _scrollDelta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  Future<void> _dropRelativeTo(
    DrawerDragItem item,
    String targetId, {
    required bool isList,
    required bool after,
  }) {
    if (!isList) {
      final peers = _drawerTags.where((tag) => tag.id != item.id).toList();
      final index = peers.indexWhere((tag) => tag.id == targetId);
      final beforeId = after && index == peers.length - 1
          ? null
          : peers[index + (after ? 1 : 0)].id;
      return widget.onMoveTag(item.id, beforeId);
    }
    final target = widget.lists.firstWhere((list) => list.id == targetId);
    final peers = _drawerLists
        .where(
          (list) =>
              list.groupId == target.groupId &&
              list.id != item.id &&
              list.id != inboxListId,
        )
        .toList();
    if (targetId == inboxListId) {
      return widget.onMoveList(item.id, null, peers.firstOrNull?.id);
    }
    final index = peers.indexWhere((list) => list.id == targetId);
    final beforeId = after && index == peers.length - 1
        ? null
        : peers[index + (after ? 1 : 0)].id;
    return widget.onMoveList(item.id, target.groupId, beforeId);
  }

  Widget _dropTarget({
    required String key,
    required bool Function(DrawerDragItem) accept,
    required Future<void> Function(DrawerDragItem) onDrop,
    Future<void> Function(DrawerDragItem item, bool after)? onDropAt,
    required Widget child,
  }) {
    BuildContext? targetContext;
    bool isAfter() {
      final box = targetContext?.findRenderObject();
      return box is RenderBox &&
          _dragPosition != null &&
          box.globalToLocal(_dragPosition!).dy >= box.size.height / 2;
    }

    return DragTarget<DrawerDragItem>(
      key: ValueKey(key),
      onWillAcceptWithDetails: (details) =>
          !_metadataBusy && _dragMoving && accept(details.data),
      onMove: (_) {
        if (onDropAt != null && mounted) setState(() {});
      },
      onAcceptWithDetails: (details) async {
        final after = isAfter();
        _dismissMenus.value++;
        setState(() => _metadataBusy = true);
        try {
          if (onDropAt == null) {
            await onDrop(details.data);
          } else {
            await onDropAt(details.data, after);
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('순서나 위치를 저장하지 못했습니다. 다시 시도해주세요.')),
            );
          }
        } finally {
          if (mounted) setState(() => _metadataBusy = false);
        }
      },
      builder: (context, candidates, _) {
        targetContext = context;
        final active = candidates.isNotEmpty;
        final side = BorderSide(color: AppTheme.primaryBlue, width: 2);
        return Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryBlue.withValues(alpha: .08)
                  : Colors.transparent,
              border: active && onDropAt != null
                  ? (isAfter() ? Border(bottom: side) : Border(top: side))
                  : null,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _manageVisibility(
    BuildContext anchor, {
    required bool isTag,
  }) async {
    final entries = isTag
        ? [for (final tag in widget.tags) (tag.id, tag.name)]
        : [
            for (final list in widget.lists)
              if (list.id != inboxListId) (list.id, list.name),
          ];
    if (entries.isEmpty) return;
    final titleStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      height: 1.3,
      color: Theme.of(context).colorScheme.onSurface,
    );
    var widest = 0.0;
    for (final (_, name) in entries) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: titleStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    final width = (widest + 64).clamp(152.0, 208.0);
    final button = anchor.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final offset = button.localToGlobal(
      Offset(0, button.size.height),
      ancestor: overlay,
    );
    await showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        offset & Size(button.size.width, 0),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints.tightFor(width: width),
      items: [
        PopupMenuItem<void>(
          height: 0,
          padding: EdgeInsets.zero,
          child: _DrawerVisibilityMenu(
            width: width,
            titleStyle: titleStyle,
            entries: entries,
            isTag: isTag,
            settings: widget.settings,
            repository: widget.settingsRepository,
            onSaved: (saved) {
              if (mounted) widget.onSettingsSaved(saved);
            },
            onError: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('숨김 설정을 저장하지 못했습니다. 다시 시도해주세요.'),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _visibilityButton({required bool isTag}) => Builder(
    builder: (anchor) => IconButton(
      tooltip: isTag ? '태그 숨김' : '목록 숨김',
      icon: const Icon(Icons.visibility_off_outlined),
      onPressed:
          widget.settingsReady &&
              (isTag
                  ? widget.tags.isNotEmpty
                  : widget.lists.any((list) => list.id != inboxListId))
          ? () => _manageVisibility(anchor, isTag: isTag)
          : null,
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
  List<Tag> get _drawerTags =>
      widget.tags
          .where((tag) => !widget.settings.hiddenTagIds.contains(tag.id))
          .toList()
        ..sort((a, b) {
          final aOrder = widget.settings.tagSortOrders[a.id];
          final bOrder = widget.settings.tagSortOrders[b.id];
          if (aOrder != null && bOrder != null && aOrder != bOrder) {
            return aOrder.compareTo(bOrder);
          }
          if (aOrder != null && bOrder == null) return -1;
          if (aOrder == null && bOrder != null) return 1;
          return a.name.compareTo(b.name);
        });

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
                  key: _drawerScrollKey,
                  controller: _drawerScroll,
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerHeading('할 일'),
                    _drawerEntry(
                      _savedPeriodLabel,
                      Icons.access_time_outlined,
                      _ScopeKind.period,
                    ),
                    _drawerEntry(
                      '전체',
                      Icons.description_outlined,
                      _ScopeKind.all,
                    ),
                    _dropTarget(
                      key: 'drawer-drop-root',
                      accept: (data) => data.kind == DrawerDragKind.list,
                      onDrop: (data) => widget.onMoveList(data.id, null, null),
                      child: _drawerHeading(
                        '목록',
                        actions: [
                          _visibilityButton(isTag: false),
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
                      _dropTarget(
                        key: 'drawer-drop-folder-${group.id}',
                        accept: (data) => data.kind == DrawerDragKind.list,
                        onDrop: (data) async {
                          await widget.onMoveList(data.id, group.id, null);
                          if (!mounted) return;
                          _expandedFolderIds.add(group.id);
                          _folderControllers[group.id]?.expand();
                        },
                        child: DrawerContextItem(
                          key: ValueKey('drawer-item-folder-${group.id}'),
                          label: group.name,
                          icon: Icons.folder_rounded,
                          dismissMenus: _dismissMenus,
                          onDragChanged: (_, _) {},
                          actions: [
                            DrawerContextAction(
                              '폴더 편집',
                              Icons.edit_outlined,
                              () => widget.onEditFolder(group),
                            ),
                            DrawerContextAction(
                              '목록 추가',
                              Icons.add_rounded,
                              () => widget.onAddListToFolder(group),
                            ),
                          ],
                          child: ExpansionTile(
                            controller: _folderControllers.putIfAbsent(
                              group.id,
                              ExpansibleController.new,
                            ),
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
                      ),
                    for (final list in _drawerLists.where(
                      (l) => l.groupId == null,
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
                        _visibilityButton(isTag: true),
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
                    ListTile(
                      key: const ValueKey('drawer-excluded'),
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('제외된 eCampus 항목'),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onOpenExcluded();
                      },
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
    if (!widget.settingsReady || _savingPeriod) return;
    final selected = await showModalBottomSheet<HomePeriod>(
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
            for (final period in HomePeriod.values.where(
              (mode) => _scope == _ScopeKind.trash || mode != HomePeriod.all,
            ))
              ListTile(
                title: Text(switch (period) {
                  HomePeriod.today => '오늘',
                  HomePeriod.week => '이번 주',
                  HomePeriod.month => '이번 달',
                  HomePeriod.all => '전체',
                  HomePeriod.custom => '기간 선택',
                }),
                trailing:
                    (_scope == _ScopeKind.trash ? _trashPeriod : _period) ==
                        period
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, period),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == HomePeriod.custom) {
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
          initialDateRange: _scope == _ScopeKind.trash
              ? _trashCustomRange
              : _customRange,
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
          initialDate:
              (_scope == _ScopeKind.trash ? _trashCustomRange : _customRange)
                  ?.start ??
              DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100, 12, 31),
          helpText: '단일 날짜 선택',
          fieldLabelText: '연 / 월 / 일',
        );
        if (date != null) range = DateTimeRange(start: date, end: date);
      }
      if (range == null || !mounted) return;
      await _savePeriod(selected, range: range);
    } else {
      await _savePeriod(selected);
    }
  }

  Future<void> _savePeriod(HomePeriod selected, {DateTimeRange? range}) async {
    if (_scope == _ScopeKind.trash) {
      setState(() {
        _trashPeriod = selected;
        _trashCustomRange = range;
        _selectedTrashIds.clear();
      });
      return;
    }
    final preference = HomePeriodPreference(
      mode: selected,
      start: range?.start,
      end: range?.end,
    );
    setState(() {
      _period = selected;
      if (range != null) _customRange = range;
      _selectedTrashIds.clear();
      _savingPeriod = true;
    });
    try {
      final latest = await widget.settingsRepository.getSettings();
      final saved = await widget.settingsRepository.saveSettings(
        latest.copyWith(homePeriod: preference),
      );
      if (mounted) widget.onSettingsSaved(saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기간을 저장하지 못했습니다. 다시 선택해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPeriod = false);
    }
  }

  Future<void> _adjustView() async {
    final isTrash = _scope == _ScopeKind.trash;
    final trash = widget.tasks
        .where((t) => t.status == TaskStatus.deleted)
        .toList();
    final trashTagIds = trash.expand((t) => t.tagIds).toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ViewOptionsSheet(
        initial: isTrash ? _trashView : _view,
        tags: isTrash
            ? widget.tags.where((t) => trashTagIds.contains(t.id)).toList()
            : widget.tags,
        statuses: isTrash
            ? [
                for (final status in [TaskStatus.active, TaskStatus.completed])
                  if (trash.any(
                    (t) =>
                        (t.completedAt == null
                            ? TaskStatus.active
                            : TaskStatus.completed) ==
                        status,
                  ))
                    status,
              ]
            : const [TaskStatus.active, TaskStatus.completed],
        priorities: isTrash
            ? TaskPriority.values
                  .where((p) => trash.any((t) => t.priority == p))
                  .toList()
            : TaskPriority.values,
        isTrash: isTrash,
        onChanged: (value) => setState(() {
          if (isTrash) {
            _trashView = value;
            _selectedTrashIds.clear();
          } else {
            _view = value;
          }
        }),
        onSave: isTrash
            ? null
            : (value) async {
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
    final view = _scope == _ScopeKind.trash ? _trashView : _view;
    final scopeMatches = switch (_scope) {
      _ScopeKind.period || _ScopeKind.all => true,
      _ScopeKind.list => task.listId == _scopeId,
      _ScopeKind.tag => task.tagIds.contains(_scopeId),
      _ScopeKind.completed => task.status == TaskStatus.completed,
      _ScopeKind.trash => task.status == TaskStatus.deleted,
    };
    if (!scopeMatches || task.status == TaskStatus.excluded) return false;
    if (_scope == _ScopeKind.trash &&
        !view.statuses.contains(
          task.completedAt == null ? TaskStatus.active : TaskStatus.completed,
        )) {
      return false;
    }
    if (_scope != _ScopeKind.trash &&
        (task.status == TaskStatus.deleted ||
            !view.statuses.contains(task.status))) {
      return false;
    }
    return (view.priorities.isEmpty ||
            view.priorities.contains(task.priority)) &&
        (view.tagIds.isEmpty || task.tagIds.any(view.tagIds.contains));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedPreferences && widget.settingsReady) {
      _view = widget.settings.homeView;
      final savedPeriod = widget.settings.homePeriod;
      _period = savedPeriod.mode;
      if (savedPeriod.mode == HomePeriod.custom) {
        _customRange = DateTimeRange(
          start: savedPeriod.start!,
          end: savedPeriod.end!,
        );
      }
      _loadedPreferences = true;
    }
    final isAll = _scope == _ScopeKind.all;
    final now = DateTime.now();
    final (start, end) = _range(now);
    bool inRange(DateTime? date) =>
        date != null &&
        !date.toLocal().isBefore(start) &&
        date.toLocal().isBefore(end);
    final matching = widget.tasks.where(_matches).toList()
      ..sort(
        (a, b) => _compare(
          a,
          b,
          (_scope == _ScopeKind.trash ? _trashView : _view).sort,
        ),
      );
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

    return PopScope(
      canPop: !_trashSelectionMode && !_trashBulkBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _trashBulkBusy) return;
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          _scaffoldKey.currentState?.closeDrawer();
        } else if (_trashSelectionMode) {
          setState(() {
            _trashSelectionMode = false;
            _selectedTrashIds.clear();
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _drawer(),
        onDrawerChanged: (open) {
          if (!open) _dismissMenus.value++;
        },
        drawerEnableOpenDragGesture: !_trashBulkBusy,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: '사이드 메뉴',
            icon: const Icon(Icons.menu_rounded),
            onPressed: _trashBulkBusy
                ? null
                : () => _scaffoldKey.currentState!.openDrawer(),
          ),
          title: InkWell(
            key: const ValueKey('home-period'),
            onTap:
                _trashBulkBusy ||
                    _savingPeriod ||
                    !widget.settingsReady ||
                    isAll
                ? null
                : _pickPeriod,
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
                          isAll
                              ? '전체'
                              : (_scope == _ScopeKind.trash
                                        ? _trashPeriod
                                        : _period) ==
                                    HomePeriod.today
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
                      if (!isAll)
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
              onPressed: _trashBulkBusy ? null : widget.onImport,
              icon: const Icon(Icons.sync_rounded),
            ),
            IconButton(
              tooltip: '보기 조정',
              onPressed: widget.settingsReady && !_trashBulkBusy
                  ? _adjustView
                  : null,
              icon: Badge(
                isLabelVisible:
                    !(_scope == _ScopeKind.trash ? _trashView : _view)
                        .isDefault,
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
            if (!_trashBulkBusy &&
                !_trashSelectionMode &&
                (_drawerDragDistance > 80 ||
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
                else if (_scope == _ScopeKind.trash) ...[
                  _trashControls(trash),
                  _section('휴지통', 'trash', trash),
                ] else ...[
                  if (_scope != _ScopeKind.completed) ...[
                    _section(
                      isAll ? '전체' : _periodLabel,
                      'period',
                      periodTasks,
                    ),
                    _section('마감 임박', 'urgent', urgent),
                    _section('마감 지남', 'overdue', overdue),
                  ],
                  _section('완료', 'completed', completed),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTrashSelection(String id) {
    setState(() {
      _trashSelectionMode = true;
      if (!_selectedTrashIds.add(id)) _selectedTrashIds.remove(id);
    });
  }

  Widget _trashControls(List<Task> visible) {
    if (!_trashSelectionMode) return const SizedBox.shrink();
    final selected = visible
        .where((t) => _selectedTrashIds.contains(t.id))
        .toList();
    final allSelected = visible.isNotEmpty && selected.length == visible.length;
    final canApply = selected.isNotEmpty && !_trashBulkBusy;
    return Padding(
      key: const ValueKey('trash-controls'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                key: const ValueKey('trash-selection-mode'),
                onPressed: _trashBulkBusy
                    ? null
                    : () => setState(() {
                        _trashSelectionMode = !_trashSelectionMode;
                        _selectedTrashIds.clear();
                      }),
                child: const Text('선택 취소'),
              ),
              if (_trashSelectionMode) ...[
                Text(_trashBulkBusy ? '처리 중…' : '${selected.length}개 선택'),
                TextButton(
                  key: const ValueKey('trash-select-all'),
                  onPressed: _trashBulkBusy || visible.isEmpty
                      ? null
                      : () => setState(() {
                          if (allSelected) {
                            _selectedTrashIds.clear();
                          } else {
                            _selectedTrashIds.addAll(visible.map((t) => t.id));
                          }
                        }),
                  child: Text(allSelected ? '전체 해제' : '전체 선택'),
                ),
              ],
            ],
          ),
          if (_trashSelectionMode)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('trash-restore-selected'),
                    onPressed: canApply
                        ? () => _applyTrashSelection(selected, restore: true)
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('선택 복원'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('trash-delete-selected'),
                    onPressed: canApply
                        ? () => _applyTrashSelection(selected, restore: false)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('선택 삭제'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _applyTrashSelection(
    List<Task> selected, {
    required bool restore,
  }) async {
    if (_trashBulkBusy || selected.isEmpty) return;
    final targets = List<Task>.of(selected);
    if (targets.any((t) => _swipingTaskIds.contains(t.id))) return;
    setState(() => _trashBulkBusy = true);
    var started = false;
    var succeeded = 0;
    var failed = 0;
    try {
      if (!restore &&
          !await _confirmTrashDeletion(selectedCount: targets.length)) {
        return;
      }
      if (!mounted) return;
      started = true;
      for (final task in targets) {
        try {
          if (restore) {
            await widget.onRestoreTask(task);
          } else {
            await widget.onDeletePermanently(task);
          }
          succeeded++;
          if (mounted) setState(() => _selectedTrashIds.remove(task.id));
        } catch (_) {
          failed++;
        }
      }
    } finally {
      if (mounted) {
        if (started) widget.onRefresh();
        setState(() {
          _trashBulkBusy = false;
          if (started && _selectedTrashIds.isEmpty) _trashSelectionMode = false;
        });
        if (started) {
          final message = failed > 0
              ? '$succeeded개 처리, $failed개 오류. 새로고침한 목록을 확인해주세요.'
              : restore
              ? '$succeeded개를 복원했습니다.'
              : '$succeeded개를 영구 삭제했습니다.';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
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
              '할 일이 없습니다.',
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
      direction:
          widget.settingsReady &&
              !_trashBulkBusy &&
              !(task.status == TaskStatus.deleted && _trashSelectionMode)
          ? DismissDirection.horizontal
          : DismissDirection.none,
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
        onTap: _trashBulkBusy
            ? null
            : task.status == TaskStatus.deleted && _trashSelectionMode
            ? () => _toggleTrashSelection(task.id)
            : () => widget.onOpenTask(task),
        leading: task.status == TaskStatus.deleted
            ? Checkbox(
                key: ValueKey('trash-select-${task.id}'),
                value: _selectedTrashIds.contains(task.id),
                onChanged: _trashBulkBusy
                    ? null
                    : (_) => _toggleTrashSelection(task.id),
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
        trailing:
            task.status == TaskStatus.deleted &&
                (_trashSelectionMode || _trashBulkBusy)
            ? null
            : task.status == TaskStatus.deleted
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
    if (_trashBulkBusy) return;
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

class _DrawerVisibilityMenu extends StatefulWidget {
  const _DrawerVisibilityMenu({
    required this.width,
    required this.titleStyle,
    required this.entries,
    required this.isTag,
    required this.settings,
    required this.repository,
    required this.onSaved,
    required this.onError,
  });
  final double width;
  final TextStyle titleStyle;
  final List<(String, String)> entries;
  final bool isTag;
  final AppSettings settings;
  final SettingsRepository repository;
  final ValueChanged<AppSettings> onSaved;
  final VoidCallback onError;
  @override
  State<_DrawerVisibilityMenu> createState() => _DrawerVisibilityMenuState();
}

class _DrawerVisibilityMenuState extends State<_DrawerVisibilityMenu> {
  late AppSettings _settings = widget.settings;
  bool _saving = false;
  Future<void> _toggle(String id) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final latest = await widget.repository.getSettings();
      final ids = {
        ...(widget.isTag ? latest.hiddenTagIds : latest.hiddenFolderIds),
      };
      if (!ids.remove(id)) ids.add(id);
      final saved = await widget.repository.saveSettings(
        widget.isTag
            ? latest.copyWith(hiddenTagIds: ids)
            : latest.copyWith(hiddenFolderIds: ids),
      );
      widget.onSaved(saved);
      if (mounted) setState(() => _settings = saved);
    } catch (_) {
      widget.onError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isHidden(String id) =>
      (widget.isTag ? _settings.hiddenTagIds : _settings.hiddenFolderIds)
          .contains(id);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: ConstrainedBox(
      key: ValueKey('visibility-menu-${widget.isTag ? 'tag' : 'list'}'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .55,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (id, name) in widget.entries)
              InkWell(
                key: ValueKey(
                  'visibility-${widget.isTag ? 'tag' : 'list'}-$id',
                ),
                onTap: _saving ? null : () => _toggle(id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: widget.titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: ValueKey('visibility-toggle-$id'),
                        tooltip: _isHidden(id) ? '보이기' : '숨기기',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 36,
                        ),
                        iconSize: 20,
                        icon: Icon(
                          _isHidden(id)
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        color: _isHidden(id)
                            ? AppTheme.muted
                            : AppTheme.primaryBlue,
                        onPressed: _saving ? null : () => _toggle(id),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
    this.onSave,
    this.statuses = const [TaskStatus.active, TaskStatus.completed],
    this.priorities = TaskPriority.values,
  });
  final HomeViewOptions initial;
  final List<Tag> tags;
  final bool isTrash;
  final ValueChanged<HomeViewOptions> onChanged;
  final Future<void> Function(HomeViewOptions)? onSave;
  final List<TaskStatus> statuses;
  final List<TaskPriority> priorities;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              widget.isTrash ? '휴지통 보기 (임시)' : '보기 조정',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isTrash) ...[
                    const Text('정렬·필터는 휴지통을 벗어나면 초기화됩니다.'),
                    const SizedBox(height: 12),
                  ],
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
                      '삭제 전 완료 여부로 구분합니다.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final status in widget.statuses)
                        FilterChip(
                          label: Text(
                            status == TaskStatus.active ? '미완료' : '완료',
                          ),
                          selected: _value.statuses.contains(status),
                          onSelected: _saving
                              ? null
                              : (_) => _change(
                                  _value.copyWith(
                                    statuses: _toggle(_value.statuses, status),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  if (widget.isTrash && widget.statuses.isEmpty)
                    const Text('휴지통에 항목이 없습니다.'),
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
                      for (final priority in widget.priorities)
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
                  if (widget.isTrash && widget.priorities.isEmpty)
                    const Text('우선순위가 지정된 항목이 없습니다.'),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        widget.isTrash ? '휴지통에 사용한 태그가 없습니다.' : '등록된 태그가 없습니다.',
                      ),
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
                if (widget.isTrash)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  )
                else
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await widget.onSave!(_value);
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

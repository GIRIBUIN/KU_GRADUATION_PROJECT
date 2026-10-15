import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../../data/local/app_database.dart' show AppDatabase;
import '../../data/models/task_models.dart';
import '../../data/services/widget_workspace_controller.dart';
import '../../data/repositories/drift_notification_repository.dart';
import '../services/local_notification_service.dart';
import 'workspace_calendar.dart';

bool get isDesktopWidgetPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

Future<void> prepareWidgetWindow() async {
  await windowManager.ensureInitialized();
  // Readiness can depend on the first Flutter frame. Awaiting it before runApp deadlocks GTK.
  unawaited(
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(360, 300),
        minimumSize: Size(150, 120),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'KU Todo 위젯',
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        await windowManager.show();
        await windowManager.setPreventClose(true);
        await windowManager.focus();
      },
    ),
  );
}

Future<void> launchDesktopWidget(WidgetKind kind) async {
  await Process.start(Platform.resolvedExecutable, [
    '--widget=${kind.name}',
  ], mode: ProcessStartMode.detached);
}

class KuWidgetApp extends StatefulWidget {
  const KuWidgetApp({super.key, required this.kind});
  final WidgetKind kind;
  @override
  State<KuWidgetApp> createState() => _KuWidgetAppState();
}

class _KuWidgetAppState extends State<KuWidgetApp> {
  late final database = AppDatabase.defaults();
  late final controller = WidgetWorkspaceController(
    database,
    widget.kind,
    notifications: LocalNotificationService(),
  );
  @override
  void dispose() {
    controller.dispose();
    database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'KU Todo 위젯',
    locale: const Locale('ko', 'KR'),
    supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: WidgetWorkspacePage(controller: controller, windowed: true),
  );
}

class WidgetWorkspacePage extends StatefulWidget {
  const WidgetWorkspacePage({
    super.key,
    required this.controller,
    this.windowed = false,
    this.initialUri,
  });
  final WidgetWorkspaceController controller;
  final bool windowed;
  final Uri? initialUri;
  @override
  State<WidgetWorkspacePage> createState() => WidgetWorkspacePageState();
}

class WidgetWorkspacePageState extends State<WidgetWorkspacePage>
    with WindowListener {
  WidgetWorkspaceController get data => widget.controller;
  Timer? _poll;
  bool _expanded = false;
  bool _settings = false;
  bool _editor = false;
  bool _advanced = false;
  bool _busy = false;
  bool _dirty = false;
  int? _reminder;
  bool _changeReminder = false;
  Rect _compactBounds = const Rect.fromLTWH(10, 10, 360, 300);
  Task? _editing;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _day;
  DateTime? _due;
  TaskPriority? _priority;
  String? _folder;
  final _title = TextEditingController();
  final _memo = TextEditingController();
  Set<String> _tags = {};

  @override
  void initState() {
    super.initState();
    _expanded = !widget.windowed;
    data.addListener(_updated);
    if (widget.windowed) windowManager.addListener(this);
    unawaited(_loadInitial());
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => data.load());
  }

  Future<void> _loadInitial() async {
    await data.load();
    if (!mounted) return;
    if (widget.windowed && data.options['alwaysOnTop'] == true) {
      await windowManager.setAlwaysOnTop(true);
    }
    final uri = widget.initialUri;
    if (uri?.queryParameters['date'] case final String date) {
      _day = DateTime.tryParse(date);
    }
    if (uri?.host == 'add') {
      _edit(null);
    } else if (uri?.queryParameters['id'] case final String id) {
      final matches = data.all.where((task) => task.id == id);
      if (matches.isNotEmpty) _edit(matches.first);
    }
    setState(() {});
  }

  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _poll?.cancel();
    data.removeListener(_updated);
    if (widget.windowed) windowManager.removeListener(this);
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  void onWindowBlur() {
    // Never throw away a draft or steal focus back when the user clicks the desktop.
    if (_expanded && !_dirty && !_busy) unawaited(_collapse());
  }

  @override
  void onWindowClose() {
    unawaited(() async {
      if (!_busy && await _discard()) await windowManager.destroy();
    }());
  }

  Future<void> _expand() async {
    if (widget.windowed) {
      _compactBounds = await windowManager.getBounds();
      final displays = await screenRetriever.getAllDisplays();
      final display =
          displays
              .where(
                (display) =>
                    ((display.visiblePosition ?? Offset.zero) &
                            (display.visibleSize ?? display.size))
                        .contains(_compactBounds.center),
              )
              .firstOrNull ??
          await screenRetriever.getPrimaryDisplay();
      final area =
          (display.visiblePosition ?? Offset.zero) &
          (display.visibleSize ?? display.size);
      final width = (area.width - 48).clamp(260.0, 420.0);
      final height = (area.height - 64).clamp(260.0, 620.0);
      await windowManager.setMinimumSize(
        Size(width.clamp(150, 300), height.clamp(150, 300)),
      );
      await windowManager.setBounds(
        Rect.fromCenter(center: area.center, width: width, height: height),
      );
    }
    if (mounted) setState(() => _expanded = true);
  }

  Future<void> _collapse() async {
    if (!await _discard()) return;
    if (!widget.windowed) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _editor = false;
      _settings = false;
      _expanded = false;
      _dirty = false;
    });
    await windowManager.setMinimumSize(const Size(150, 120));
    await windowManager.setBounds(_compactBounds);
  }

  Future<void> close() => _collapse();

  Future<bool> _discard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('작성 중인 내용을 버릴까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 작성'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('버리기'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted && data.notice != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data.notice!)));
        data.notice = null;
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(Task? task) {
    setState(() {
      _editing = task;
      _editor = true;
      _settings = false;
      _advanced = false;
      _dirty = false;
      _title.text = task?.title ?? '';
      _memo.text = task?.memo ?? '';
      _due = task == null
          ? DateTime(
              (_day ?? DateTime.now()).year,
              (_day ?? DateTime.now()).month,
              (_day ?? DateTime.now()).day,
              23,
              59,
            )
          : task.dueDate;
      _priority = task?.priority;
      _tags = task?.tagIds.toSet() ?? {};
      _folder = task?.folderIds.firstOrNull;
      _reminder =
          task == null && (!isDesktopWidgetPlatform || !Platform.isLinux)
          ? data.defaultReminderMinutes
          : null;
      _changeReminder = task == null;
    });
    if (task != null) {
      unawaited(
        DriftNotificationRepository(
          database: data.database,
        ).getByTaskId(task.id).then((value) {
          if (mounted && _editing?.id == task.id && !_changeReminder) {
            setState(
              () => _reminder = value?.enabled == true
                  ? value?.daysBeforeDue
                  : null,
            );
          }
        }),
      );
    }
  }

  Future<void> _save() => _run(() async {
    await data.save(
      existing: _editing,
      title: _title.text,
      due: _due,
      memo: _memo.text,
      priority: _priority,
      tagIds: _tags.toList(),
      folderId: _folder,
      changeReminder: _changeReminder,
      reminderMinutes: _reminder,
    );
    if (mounted) {
      setState(() {
        _editor = false;
        _dirty = false;
      });
    }
  });

  ThemeData _theme() {
    final dark = data.theme == WidgetTheme.dark;
    final surface = switch (data.theme) {
      WidgetTheme.dark => const Color(0xff1c2535),
      WidgetTheme.gray => const Color(0xffe7e9ee),
      _ => Colors.white,
    };
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff1262d6),
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(surface: surface),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _theme(),
    child: Builder(
      builder: (context) {
        final surface = Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: data.opacity);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _expanded ? _collapse : null,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: _editor
                            ? MainAxisSize.min
                            : MainAxisSize.max,
                        children: [
                          if (_expanded) _header(context),
                          if (data.error != null)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                data.error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          Flexible(
                            fit: _editor ? FlexFit.loose : FlexFit.tight,
                            child: !_expanded
                                ? _compact(context)
                                : _settings
                                ? _preferences(context)
                                : _editor
                                ? _form(context)
                                : _workspace(context),
                          ),
                          if (_editor && _expanded)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _busy ? null : _save,
                                child: Text(_busy ? '저장 중…' : '저장'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      Expanded(
        child: GestureDetector(
          onPanStart: widget.windowed
              ? (_) => windowManager.startDragging()
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _editor
                  ? (_editing == null ? '새 일정' : '일정 수정')
                  : _settings
                  ? '위젯 설정'
                  : data.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ),
      TextButton(onPressed: _busy ? null : _collapse, child: const Text('닫기')),
    ],
  );

  Widget _compact(BuildContext context) {
    final list = data.select();
    if (data.kind == WidgetKind.calendar) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _expand,
        onPanStart: (_) => windowManager.startDragging(),
        child: WorkspaceCalendar(
          month: _month,
          tasks: list,
          adaptive: true,
          onDay: (day) async {
            _day = day;
            await _expand();
          },
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _expand,
      onPanStart: (_) => windowManager.startDragging(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text('${list.length}개', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = (constraints.maxHeight ~/ 42).clamp(0, 12);
                if (list.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '등록된 일정이 없습니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final task in list.take(count))
                      SizedBox(
                        height: 42,
                        child: Row(
                          children: [
                            Icon(
                              task.status == TaskStatus.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspace(BuildContext context) {
    final list = data.select(
      day: data.kind == WidgetKind.calendar ? _day : null,
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _edit(null),
                child: const Text('+ 추가'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () => _menu(context),
                child: const Text('더 보기'),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              if (data.kind == WidgetKind.calendar)
                SizedBox(
                  height: 280,
                  child: WorkspaceCalendar(
                    month: _month,
                    tasks: data.select(),
                    onMonth: (value) => setState(() => _month = value),
                    onDay: (value) => setState(() => _day = value),
                  ),
                ),
              if (_day != null && data.kind == WidgetKind.calendar)
                Row(
                  children: [
                    Expanded(child: Text('${_day!.month}월 ${_day!.day}일')),
                    TextButton(
                      onPressed: () => setState(() => _day = null),
                      child: const Text('전체 날짜'),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '일정 검색',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (value) => setState(() => data.search = value),
                ),
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('표시할 일정이 없습니다.'),
                ),
              for (final task in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Checkbox(
                    value: task.status == TaskStatus.completed,
                    onChanged:
                        _busy ||
                            task.status == TaskStatus.deleted ||
                            task.status == TaskStatus.excluded
                        ? null
                        : (_) => _run(
                            () => data.status(
                              task,
                              task.status == TaskStatus.completed
                                  ? TaskStatus.active
                                  : TaskStatus.completed,
                            ),
                          ),
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    task.dueDate == null
                        ? '기한 없음'
                        : '${task.dueDate!.month}/${task.dueDate!.day} ${TimeOfDay.fromDateTime(task.dueDate!).format(context)}',
                  ),
                  trailing: data.pins.contains(task.id)
                      ? const Icon(Icons.push_pin, size: 16)
                      : null,
                  onTap: () => _edit(task),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) => SingleChildScrollView(
    key: ValueKey('editor-${_editing?.id ?? 'new'}'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('widget-title'),
          autofocus: isDesktopWidgetPlatform,
          controller: _title,
          decoration: const InputDecoration(hintText: '제목'),
          onChanged: (_) => _dirty = true,
        ),
        const SizedBox(height: 6),
        TwoWeekDuePicker(
          value: _due,
          readOnly: _editing?.isEcampus == true,
          onChanged: (value) => setState(() {
            _due = value;
            _dirty = true;
          }),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _memo,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '메모'),
          onChanged: (_) => _dirty = true,
        ),
        TextButton(
          onPressed: () => _chooseTags(context),
          child: Text('태그 선택 (${_tags.length})'),
        ),
        TextButton(
          onPressed: () => setState(() => _advanced = !_advanced),
          child: Text(_advanced ? '접기 ▴' : '더 보기 ▾'),
        ),
        if (_advanced) ...[
          if (!isDesktopWidgetPlatform || !Platform.isLinux)
            DropdownButtonFormField<int?>(
              key: ValueKey(_reminder),
              initialValue: _reminder,
              decoration: const InputDecoration(labelText: '마감 알림'),
              items: [
                const DropdownMenuItem(value: null, child: Text('꺼짐')),
                for (final minutes in {
                  ...[0, 5, 15, 30, 60, 1440],
                  ?_reminder,
                })
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(minutes == 0 ? '마감 시각' : '$minutes분 전'),
                  ),
              ],
              onChanged: _due == null
                  ? null
                  : (value) => setState(() {
                      _reminder = value;
                      _changeReminder = true;
                      _dirty = true;
                    }),
            ),
          if (isDesktopWidgetPlatform && Platform.isLinux)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Linux에서는 OS의 예약 알림을 지원하지 않습니다.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          DropdownButtonFormField<TaskPriority?>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: '우선순위'),
            items: [
              const DropdownMenuItem(value: null, child: Text('없음')),
              for (final priority in TaskPriority.values)
                DropdownMenuItem(
                  value: priority,
                  child: Text(['높음', '보통', '낮음'][priority.index]),
                ),
            ],
            onChanged: (value) => setState(() {
              _priority = value;
              _dirty = true;
            }),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            initialValue: _folder,
            decoration: const InputDecoration(labelText: '폴더'),
            items: [
              const DropdownMenuItem(value: null, child: Text('없음')),
              for (final folder in data.folders)
                DropdownMenuItem(value: folder.id, child: Text(folder.name)),
            ],
            onChanged: (value) => setState(() {
              _folder = value;
              _dirty = true;
            }),
          ),
          Wrap(
            children: [
              TextButton(
                onPressed: () => _newMetadata(context, false),
                child: const Text('태그 만들기'),
              ),
              TextButton(
                onPressed: () => _newMetadata(context, true),
                child: const Text('폴더 만들기'),
              ),
            ],
          ),
          if (_editing == null)
            Wrap(
              children: [
                for (final name in ['과제 작업', '시험 공부', '팀 미팅', '개인 일정'])
                  ActionChip(
                    label: Text(name),
                    onPressed: () {
                      _title.text = name;
                      _dirty = true;
                    },
                  ),
              ],
            ),
          if (_editing case final Task task) ...[
            Wrap(
              children: [
                TextButton(
                  onPressed: () => _run(() => data.pin(task)),
                  child: Text(
                    data.pins.contains(task.id) ? '고정 해제' : '중요 일정 고정',
                  ),
                ),
                if (!task.isEcampus)
                  for (final days in [1, 7])
                    TextButton(
                      onPressed: _due == null
                          ? null
                          : () => setState(() {
                              _due = DateTime(
                                _due!.year,
                                _due!.month,
                                _due!.day + days,
                                _due!.hour,
                                _due!.minute,
                              );
                              _dirty = true;
                            }),
                      child: Text('$days일 미루기'),
                    ),
                TextButton(
                  onPressed: () {
                    final title = _title.text;
                    final memo = _memo.text;
                    _edit(null);
                    setState(() {
                      _title.text = title;
                      _memo.text = memo;
                      _dirty = true;
                    });
                  },
                  child: const Text('기본 정보 복사'),
                ),
              ],
            ),
            _subTaskList(task),
            TextButton(
              onPressed: () => _confirmStatus(
                context,
                task,
                task.status == TaskStatus.deleted ||
                        task.status == TaskStatus.excluded
                    ? TaskStatus.active
                    : TaskStatus.deleted,
              ),
              child: Text(
                task.status == TaskStatus.deleted ||
                        task.status == TaskStatus.excluded
                    ? '복구'
                    : '삭제',
              ),
            ),
            if (task.isEcampus)
              TextButton(
                onPressed: () =>
                    _confirmStatus(context, task, TaskStatus.excluded),
                child: const Text('동기화에서 제외'),
              ),
          ],
        ],
      ],
    ),
  );

  Future<void> _chooseTags(BuildContext context) async {
    final chosen = {..._tags};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('태그 선택'),
          content: SizedBox(
            width: 280,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final tag in data.tags)
                  CheckboxListTile(
                    title: Text(tag.name),
                    value: chosen.contains(tag.id),
                    onChanged: (value) => update(() {
                      if (value == true) {
                        chosen.add(tag.id);
                      } else {
                        chosen.remove(tag.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, chosen),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _tags = result;
        _dirty = true;
      });
    }
  }

  Future<String?> _askText(
    BuildContext context,
    String title, [
    String initial = '',
  ]) async {
    final text = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    // Dialog animation may still be reading its controller during route removal.
    Future<void>.delayed(const Duration(seconds: 1), text.dispose);
    return result;
  }

  Future<void> _newMetadata(BuildContext context, bool folder) async {
    final text = await _askText(context, folder ? '폴더 만들기' : '태그 만들기');
    if (text != null && text.isNotEmpty) {
      await _run(() => folder ? data.addFolder(text) : data.addTag(text));
    }
  }

  Widget _subTaskList(Task task) => FutureBuilder<List<SubTask>>(
    future: data.subTasks.getSubTasks(task.id),
    builder: (context, snapshot) => Column(
      children: [
        for (final sub in snapshot.data ?? <SubTask>[])
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sub.title),
                  value: sub.isDone,
                  onChanged: _busy
                      ? null
                      : (value) => _run(() async {
                          await data.subTasks.updateSubTaskDone(sub.id, value!);
                          await data.load();
                        }),
                ),
              ),
              IconButton(
                tooltip: '하위 작업 삭제',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _run(() async {
                  await data.subTasks.deleteSubTask(sub.id);
                  await data.load();
                }),
              ),
            ],
          ),
        TextButton(
          onPressed: () async {
            final text = await _askText(context, '하위 작업');
            if (text == null || text.isEmpty) return;
            await _run(() async {
              await data.subTasks.createSubTask(
                SubTask(
                  id: WidgetWorkspaceController.newId(),
                  taskId: task.id,
                  title: text,
                  isDone: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              await data.load();
            });
          },
          child: const Text('+ 하위 작업'),
        ),
      ],
    ),
  );

  Future<void> _confirmStatus(
    BuildContext context,
    Task task,
    TaskStatus status,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == TaskStatus.active ? '복구할까요?' : '목록에서 제거할까요?'),
        content: const Text('삭제·제외 목록에서 다시 복구할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _run(() async {
        await data.status(task, status);
        if (mounted) {
          setState(() {
            _editor = false;
            _dirty = false;
          });
        }
      });
    }
  }

  Future<void> _menu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in {
              'settings': '필터·설정',
              'undo': '직전 상태 변경 되돌리기',
              'timer': '집중 타이머',
              'refresh': '새로고침',
              if (widget.windowed) 'quit': '위젯 종료',
            }.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.pop(context, entry.key),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'settings':
        setState(() => _settings = true);
      case 'undo':
        await _run(data.undo);
      case 'refresh':
        await _run(data.load);
      case 'timer':
        if (context.mounted) await _timer(context);
      case 'quit':
        await windowManager.close();
    }
  }

  Future<void> _timer(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('집중 타이머'),
        content: StreamBuilder<int>(
          stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
          builder: (context, _) => FutureBuilder<DateTime?>(
            future: data.focusEnd(),
            builder: (context, value) {
              final seconds =
                  (value.data?.difference(DateTime.now()).inSeconds ?? 0).clamp(
                    0,
                    86400,
                  );
              return Text(
                '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 28),
              );
            },
          ),
        ),
        actions: [
          for (final minutes in [15, 25, 50])
            TextButton(
              onPressed: () => data.startFocus(minutes),
              child: Text('$minutes분'),
            ),
          TextButton(
            onPressed: () => data.startFocus(0),
            child: const Text('초기화'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _preferences(BuildContext context) => ListView(
    children: [
      _setting<String>('기간', data.period, {
        'today': '오늘',
        'week': '이번 주',
        'all': '전체',
        'urgent': '마감 임박',
        'overdue': '기한 초과',
        'pinned': '중요 일정',
        'trash': '삭제·제외',
      }, (value) => data.configure({'period': value})),
      _setting<String>(
        '유형',
        data.options['origin'] as String? ?? 'all',
        {'all': '전체', 'personal': '개인', 'ecampus': '학업'},
        (value) => data.configure({'origin': value}),
      ),
      _setting<String>(
        '태그',
        data.options['tag'] as String? ?? '',
        {'': '전체', for (final tag in data.tags) tag.id: tag.name},
        (value) => data.configure({'tag': value == '' ? null : value}),
      ),
      _setting<String>(
        '폴더',
        data.options['folder'] as String? ?? '',
        {'': '전체', for (final folder in data.folders) folder.id: folder.name},
        (value) => data.configure({'folder': value == '' ? null : value}),
      ),
      _setting<String>(
        '정렬',
        data.options['sort'] as String? ?? 'due',
        {'due': '마감일', 'priority': '우선순위', 'order': '앱의 사용자 순서'},
        (value) => data.configure({'sort': value}),
      ),
      _setting<WidgetTheme>(
        '테마',
        data.theme,
        {
          WidgetTheme.light: '밝게',
          WidgetTheme.dark: '어둡게',
          WidgetTheme.gray: '회색',
          WidgetTheme.glass: '반투명',
        },
        (value) => data.configure({
          'theme': value.name,
          'opacity': value == WidgetTheme.glass ? .7 : 1.0,
        }),
      ),
      const Text('배경 불투명도'),
      Slider(
        value: data.opacity,
        min: .2,
        max: 1,
        divisions: 16,
        onChanged: (value) => data.configure({'opacity': value}),
      ),
      CheckboxListTile(
        title: const Text('완료된 일정 표시'),
        value: data.options['showCompleted'] == true,
        onChanged: (value) => data.configure({'showCompleted': value}),
      ),
      if (widget.windowed)
        CheckboxListTile(
          title: const Text('다른 창 위에 고정'),
          value: data.options['alwaysOnTop'] == true,
          onChanged: (value) async {
            await windowManager.setAlwaysOnTop(value!);
            await data.configure({'alwaysOnTop': value});
          },
        ),
      TextButton(
        onPressed: () => setState(() => _settings = false),
        child: const Text('설정 완료'),
      ),
    ],
  );

  Widget _setting<T>(
    String title,
    T value,
    Map<T, String> values,
    Future<void> Function(T) change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$title:$value'),
      initialValue: values.containsKey(value) ? value : values.keys.first,
      decoration: InputDecoration(labelText: title),
      items: [
        for (final entry in values.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: _busy
          ? null
          : (value) {
              if (value != null) unawaited(_run(() => change(value)));
            },
    ),
  );
}

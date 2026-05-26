import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ecampus_models.dart';
import '../../../data/models/task_models.dart';
import '../../../data/services/ecampus_sync_flow_service.dart';

class EcampusSyncPreviewScreen extends StatefulWidget {
  const EcampusSyncPreviewScreen({
    super.key,
    required this.syncResult,
    required this.syncFlowService,
  });

  final SyncResult syncResult;
  final EcampusSyncFlowService syncFlowService;

  @override
  State<EcampusSyncPreviewScreen> createState() =>
      _EcampusSyncPreviewScreenState();
}

class _EcampusSyncPreviewScreenState extends State<EcampusSyncPreviewScreen> {
  late final Set<String> _selectedKeys;
  final Set<String> _savedExcludeKeys = {};
  final Set<String> _allowedExcludeKeys = {};
  final Set<String> _importedKeys = {};
  final Map<String, Task> _excludedTasksByKey = {};
  final Map<String, SyncItem> _savedExcludedItemsByKey = {};
  final Map<String, SyncItem> _importedItemsByKey = {};
  var _isSaving = false;
  var _isExcluding = false;
  var _isAllowing = false;
  var _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedKeys = {
      for (final item in widget.syncResult.importCandidates) _itemKey(item),
    };
    _hasChanges = widget.syncResult.items.any(_isAutoCompletedItem);
  }

  @override
  Widget build(BuildContext context) {
    final ignoredItems = widget.syncResult.ignoredItems;
    final visibleImportCandidates = _visibleImportCandidates();
    final excludedItems = [
      ...ignoredItems.where(
        (item) =>
            item.kind == SyncItemKind.excluded &&
            !_allowedExcludeKeys.contains(_itemKey(item)),
      ),
      ..._savedExcludedItemsByKey.values,
    ];
    final importedItems = [
      ...ignoredItems.where((item) => item.kind != SyncItemKind.excluded),
      ..._importedItemsByKey.values,
    ];
    final errorItems = widget.syncResult.errorItems;
    final newCount = widget.syncResult.items
        .where((item) => item.kind == SyncItemKind.newItem)
        .length;
    final updateCount = widget.syncResult.items
        .where((item) => item.kind == SyncItemKind.updateCandidate)
        .length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _closePreview();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('동기화 미리보기')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            children: [
              Card(
                color: AppTheme.successGreen.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8F6EE),
                        child: Icon(
                          Icons.sync_rounded,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '새 항목 $newCount개, 업데이트 후보 $updateCount개 감지',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: '가져올 항목',
                count: visibleImportCandidates.length,
                trailing: TextButton(
                  onPressed: visibleImportCandidates.isEmpty
                      ? null
                      : _selectAll,
                  child: const Text('모두 선택'),
                ),
              ),
              const SizedBox(height: 10),
              if (visibleImportCandidates.isEmpty)
                const _EmptyPreviewCard(message: '새로 가져올 항목이 없습니다.')
              else
                for (final item in visibleImportCandidates) ...[
                  _SyncItemCard(
                    item: item,
                    selected: _selectedKeys.contains(_itemKey(item)),
                    onChanged: (selected) => _toggle(item, selected),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 24),
              _SectionTitle(title: '제외된 항목', count: excludedItems.length),
              const SizedBox(height: 10),
              if (excludedItems.isEmpty)
                const _EmptyPreviewCard(message: '제외된 항목이 없습니다.')
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < excludedItems.length; i++) ...[
                        _ExcludedPreviewItemTile(
                          item: excludedItems[i],
                          isBusy: _isAllowing,
                          onMoveToImport: () => _moveToImport(excludedItems[i]),
                        ),
                        if (i != excludedItems.length - 1)
                          const Divider(height: 1, indent: 60),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              _SectionTitle(title: '가져온 항목', count: importedItems.length),
              const SizedBox(height: 10),
              if (importedItems.isEmpty)
                const _EmptyPreviewCard(message: '이미 가져온 항목이 없습니다.')
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < importedItems.length; i++) ...[
                        _IgnoredItemTile(item: importedItems[i]),
                        if (i != importedItems.length - 1)
                          const Divider(height: 1, indent: 60),
                      ],
                    ],
                  ),
                ),
              if (errorItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionTitle(title: '파싱 실패', count: errorItems.length),
                const SizedBox(height: 10),
                Card(
                  color: AppTheme.dangerRed.withValues(alpha: 0.06),
                  child: Column(
                    children: [
                      for (final item in errorItems)
                        ListTile(
                          leading: const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.dangerRed,
                          ),
                          title: Text(item.errorMessage ?? '알 수 없는 오류'),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : _closePreview,
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedKeys.isEmpty || _isBusy
                          ? null
                          : _excludeSelectedItems,
                      icon: _isExcluding
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.block_rounded, size: 18),
                      label: const Text('선택 제외'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedKeys.isEmpty || _isBusy
                      ? null
                      : _importSelectedItems,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('가져오기 (${_selectedKeys.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isBusy => _isSaving || _isExcluding || _isAllowing;

  void _closePreview() {
    if (_isBusy) {
      return;
    }
    Navigator.of(context).pop(_hasChanges ? true : null);
  }

  bool _isMovedFromImportSection(SyncItem item) {
    final key = _itemKey(item);
    return _savedExcludeKeys.contains(key) || _importedKeys.contains(key);
  }

  void _toggle(SyncItem item, bool selected) {
    setState(() {
      final key = _itemKey(item);
      if (selected) {
        _selectedKeys.add(key);
      } else {
        _selectedKeys.remove(key);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedKeys
        ..clear()
        ..addAll(
          widget.syncResult.importCandidates
              .followedBy(_allowedImportCandidates())
              .where((item) => !_isMovedFromImportSection(item))
              .map(_itemKey),
        );
    });
  }

  Future<void> _importSelectedItems() async {
    final selectedItems = _visibleImportCandidates()
        .where((item) => _selectedKeys.contains(_itemKey(item)))
        .toList(growable: false);

    if (selectedItems.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final importedTasks = await widget.syncFlowService.importItems(
        selectedItems,
        syncedAt: widget.syncResult.syncedAt,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('가져오기 완료'),
          content: Text('${importedTasks.length}개 항목을 저장했습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (mounted) {
        setState(() {
          for (final item in selectedItems) {
            final key = _itemKey(item);
            _importedKeys.add(key);
            _importedItemsByKey[key] = item;
            _selectedKeys.remove(key);
          }
          _isSaving = false;
          _hasChanges = true;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('가져오기에 실패했습니다: $error')));
    }
  }

  Future<void> _excludeSelectedItems() async {
    final selectedItems = _visibleImportCandidates()
        .where(
          (item) =>
              _selectedKeys.contains(_itemKey(item)) &&
              !_isMovedFromImportSection(item),
        )
        .toList(growable: false);

    if (selectedItems.isEmpty) {
      return;
    }

    setState(() {
      _isExcluding = true;
    });

    try {
      final excludedTasks = await widget.syncFlowService.excludeItems(
        selectedItems,
        syncedAt: widget.syncResult.syncedAt,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        for (final task in excludedTasks) {
          final sourceKey = task.ecampus?.sourceKey;
          if (sourceKey != null && sourceKey.isNotEmpty) {
            _excludedTasksByKey[sourceKey] = task;
          }
        }
        for (final item in selectedItems) {
          final key = _itemKey(item);
          _savedExcludeKeys.add(key);
          _savedExcludedItemsByKey[key] = item;
          _allowedExcludeKeys.remove(key);
          _selectedKeys.remove(key);
        }
        _isExcluding = false;
        _hasChanges = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isExcluding = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('제외에 실패했습니다: $error')));
    }
  }

  Future<void> _moveToImport(SyncItem item) async {
    final key = _itemKey(item);
    final excludedTask = item.existingTask ?? _excludedTasksByKey[key];
    if (excludedTask == null) {
      return;
    }

    setState(() {
      _isAllowing = true;
    });

    try {
      await widget.syncFlowService.allowExcludedTasks([excludedTask]);
      if (!mounted) {
        return;
      }

      setState(() {
        _savedExcludeKeys.remove(key);
        _allowedExcludeKeys.add(key);
        _excludedTasksByKey.remove(key);
        _savedExcludedItemsByKey.remove(key);
        _isAllowing = false;
        _hasChanges = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAllowing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('다시 가져오기에 실패했습니다: $error')));
    }
  }

  SyncItem? _copyAsImportCandidate(SyncItem item) {
    final parsedTask = item.parsedTask;
    if (parsedTask == null) {
      return null;
    }
    return SyncItem(kind: SyncItemKind.newItem, parsedTask: parsedTask);
  }

  List<SyncItem> _visibleImportCandidates() {
    return widget.syncResult.importCandidates
        .where((item) => !_isMovedFromImportSection(item))
        .followedBy(_allowedImportCandidates())
        .toList(growable: false);
  }

  List<SyncItem> _allowedImportCandidates() {
    return widget.syncResult.ignoredItems
        .where(
          (item) =>
              item.kind == SyncItemKind.excluded &&
              _allowedExcludeKeys.contains(_itemKey(item)) &&
              !_importedKeys.contains(_itemKey(item)),
        )
        .map(_copyAsImportCandidate)
        .whereType<SyncItem>()
        .toList(growable: false);
  }
}

class _SyncItemCard extends StatelessWidget {
  const _SyncItemCard({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final SyncItem item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final parsedTask = item.parsedTask;
    final dueLabel = parsedTask?.dueLabel;
    final badge = item.kind == SyncItemKind.newItem ? '신규' : '업데이트';
    final badgeColor = item.kind == SyncItemKind.newItem
        ? AppTheme.successGreen
        : AppTheme.warningOrange;

    return Card(
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value!),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            parsedTask?.title ?? '제목 없음',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _MiniChip(
                          label: badge,
                          color: badgeColor,
                          filled: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      parsedTask?.course ?? 'e-campus',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ?(dueLabel == null
                            ? null
                            : _MiniChip(label: dueLabel, color: badgeColor)),
                      ],
                    ),
                    if (item.kind == SyncItemKind.updateCandidate &&
                        item.existingTask?.dueDate != parsedTask?.dueDate) ...[
                      const SizedBox(height: 8),
                      Text(
                        '마감일 변경 후보',
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _IgnoredItemTile extends StatelessWidget {
  const _IgnoredItemTile({required this.item});

  final SyncItem item;

  @override
  Widget build(BuildContext context) {
    final parsedTask = item.parsedTask;
    return ListTile(
      leading: const Icon(Icons.remove_circle_outline_rounded),
      title: Text(
        parsedTask?.title ??
            item.existingTask?.title ??
            item.errorMessage ??
            '항목 없음',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        parsedTask?.course ??
            item.existingTask?.ecampus?.sourceCourse ??
            'e-campus',
      ),
      trailing: _MiniChip(label: _kindLabel(item.kind), color: AppTheme.muted),
    );
  }
}

class _ExcludedPreviewItemTile extends StatelessWidget {
  const _ExcludedPreviewItemTile({
    required this.item,
    required this.isBusy,
    required this.onMoveToImport,
  });

  final SyncItem item;
  final bool isBusy;
  final VoidCallback onMoveToImport;

  @override
  Widget build(BuildContext context) {
    final parsedTask = item.parsedTask;
    return ListTile(
      leading: const Icon(Icons.block_rounded, color: AppTheme.warningOrange),
      title: Text(
        parsedTask?.title ?? item.existingTask?.title ?? '항목 없음',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(parsedTask?.course ?? 'e-campus'),
      trailing: TextButton(
        onPressed: isBusy ? null : onMoveToImport,
        child: const Text('다시 가져오기'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    this.trailing,
  });

  final String title;
  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        _MiniChip(label: '$count', color: AppTheme.successGreen),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyPreviewCard extends StatelessWidget {
  const _EmptyPreviewCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(message, style: const TextStyle(color: AppTheme.muted)),
        ),
      ),
    );
  }
}

String _itemKey(SyncItem item) {
  return item.parsedTask?.sourceKey ??
      item.existingTask?.id ??
      item.errorMessage ??
      item.kind.name;
}

bool _isAutoCompletedItem(SyncItem item) {
  return item.kind == SyncItemKind.completed &&
      item.parsedTask == null &&
      item.existingTask != null;
}

String _kindLabel(SyncItemKind kind) {
  return switch (kind) {
    SyncItemKind.newItem => '신규',
    SyncItemKind.updateCandidate => '업데이트',
    SyncItemKind.alreadyImported => '가져옴',
    SyncItemKind.completed => '완료',
    SyncItemKind.deleted => '삭제됨',
    SyncItemKind.excluded => '제외됨',
    SyncItemKind.error => '오류',
  };
}

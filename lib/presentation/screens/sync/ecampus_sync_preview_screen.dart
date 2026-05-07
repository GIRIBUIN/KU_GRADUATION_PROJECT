import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ecampus_models.dart';

class EcampusSyncPreviewScreen extends StatefulWidget {
  const EcampusSyncPreviewScreen({super.key, required this.syncResult});

  final SyncResult syncResult;

  @override
  State<EcampusSyncPreviewScreen> createState() =>
      _EcampusSyncPreviewScreenState();
}

class _EcampusSyncPreviewScreenState extends State<EcampusSyncPreviewScreen> {
  late final Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = {
      for (final item in widget.syncResult.importCandidates) _itemKey(item),
    };
  }

  @override
  Widget build(BuildContext context) {
    final importCandidates = widget.syncResult.importCandidates;
    final ignoredItems = widget.syncResult.ignoredItems;
    final errorItems = widget.syncResult.errorItems;
    final newCount = widget.syncResult.items
        .where((item) => item.kind == SyncItemKind.newItem)
        .length;
    final updateCount = widget.syncResult.items
        .where((item) => item.kind == SyncItemKind.updateCandidate)
        .length;

    return Scaffold(
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
              count: importCandidates.length,
              trailing: TextButton(
                onPressed: importCandidates.isEmpty ? null : _selectAll,
                child: const Text('모두 선택'),
              ),
            ),
            const SizedBox(height: 10),
            if (importCandidates.isEmpty)
              const _EmptyPreviewCard(message: '새로 가져올 항목이 없습니다.')
            else
              for (final item in importCandidates) ...[
                _SyncItemCard(
                  item: item,
                  selected: _selectedKeys.contains(_itemKey(item)),
                  onChanged: (selected) => _toggle(item, selected),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 24),
            _SectionTitle(title: '가져오지 않을 항목', count: ignoredItems.length),
            const SizedBox(height: 10),
            if (ignoredItems.isEmpty)
              const _EmptyPreviewCard(message: '건너뛸 항목이 없습니다.')
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < ignoredItems.length; i++) ...[
                      _IgnoredItemTile(item: ignoredItems[i]),
                      if (i != ignoredItems.length - 1)
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _selectedKeys.isEmpty ? null : _showNextStepNotice,
                child: Text('선택 항목 ${_selectedKeys.length}개 가져오기'),
              ),
            ),
          ],
        ),
      ),
    );
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
        ..addAll(widget.syncResult.importCandidates.map(_itemKey));
    });
  }

  void _showNextStepNotice() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('선택 항목 저장은 다음 커밋에서 연결합니다.')));
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
                        _MiniChip(label: badge, color: badgeColor, filled: true),
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
        parsedTask?.title ?? item.errorMessage ?? '항목 없음',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(parsedTask?.course ?? 'e-campus'),
      trailing: _MiniChip(label: _kindLabel(item.kind), color: AppTheme.muted),
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

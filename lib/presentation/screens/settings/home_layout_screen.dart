import 'package:flutter/material.dart';

import '../../../data/models/home_section.dart';
import '../../../data/repositories/settings_repository.dart';

class HomeLayoutScreen extends StatefulWidget {
  const HomeLayoutScreen({
    super.key,
    required this.settings,
    required this.settingsRepository,
  });

  final AppSettings settings;
  final SettingsRepository settingsRepository;

  @override
  State<HomeLayoutScreen> createState() => _HomeLayoutScreenState();
}

class _HomeLayoutScreenState extends State<HomeLayoutScreen> {
  late final List<HomeSection> _order;
  late final Set<HomeSection> _hidden;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.settings.homeSectionOrder);
    _hidden = Set.of(widget.settings.hiddenHomeSections);
  }

  void _restoreDefaults() {
    setState(() {
      _order
        ..clear()
        ..addAll(HomeSection.values);
      _hidden
        ..clear()
        ..addAll(HomeSection.defaultHidden);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      // Preserve settings changed elsewhere while this editor was open.
      final latest = await widget.settingsRepository.getSettings();
      final saved = await widget.settingsRepository.saveSettings(
        latest.copyWith(
          homeSectionOrder: List.unmodifiable(_order),
          hiddenHomeSections: Set.unmodifiable(_hidden),
        ),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('홈 화면 구성을 저장하지 못했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('홈 화면 구성'),
          actions: [
            IconButton(
              tooltip: '기본 구성으로 복원',
              onPressed: _isSaving ? null : _restoreDefaults,
              icon: const Icon(Icons.restore_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            buildDefaultDragHandles: false,
            itemCount: _order.length,
            onReorderItem: (oldIndex, newIndex) {
              if (_isSaving) return;
              setState(() {
                _order.insert(newIndex, _order.removeAt(oldIndex));
              });
            },
            itemBuilder: (context, index) {
              final section = _order[index];
              final visible = !_hidden.contains(section);
              return Material(
                key: ValueKey(section.id),
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        enabled: !_isSaving,
                        child: Semantics(
                          label: '${section.label} 순서 변경',
                          child: Tooltip(
                            message: '${section.label} 순서 변경',
                            child: SizedBox(
                              width: 48,
                              height: 64,
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Semantics(
                        label: '${section.label} 표시',
                        child: Switch(
                          value: visible,
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() {
                                  if (value) {
                                    _hidden.remove(section);
                                  } else {
                                    _hidden.add(section);
                                  }
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('저장'),
            ),
          ),
        ),
      ),
    );
  }
}

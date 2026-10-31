import 'package:flutter/material.dart';

import '../../../data/models/task_swipe_options.dart';
import '../../../data/repositories/settings_repository.dart';

class TaskSwipeSettingsSheet extends StatefulWidget {
  const TaskSwipeSettingsSheet({
    super.key,
    required this.settings,
    required this.repository,
    required this.onSaved,
  });

  final AppSettings settings;
  final SettingsRepository repository;
  final ValueChanged<AppSettings> onSaved;

  @override
  State<TaskSwipeSettingsSheet> createState() => _TaskSwipeSettingsSheetState();
}

class _TaskSwipeSettingsSheetState extends State<TaskSwipeSettingsSheet> {
  late TaskSwipeOptions _value = widget.settings.taskSwipes;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    var completed = false;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final latest = await widget.repository.getSettings();
      final saved = await widget.repository.saveSettings(
        latest.copyWith(taskSwipes: _value),
      );
      widget.onSaved(saved);
      completed = true;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = '설정을 저장하지 못했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted && !completed) setState(() => _saving = false);
    }
  }

  Widget _choice(
    String id,
    String label,
    TaskSwipeAction value,
    List<TaskSwipeAction> allowed,
    ValueChanged<TaskSwipeAction> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: DropdownButtonFormField<TaskSwipeAction>(
      key: ValueKey('swipe-setting-$id'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final action in allowed)
          DropdownMenuItem(value: action, child: Text(action.label)),
      ],
      onChanged: _saving
          ? null
          : (action) {
              if (action != null) setState(() => onChanged(action));
            },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '스와이프 동작',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      '할 일 행을 밀면 지정한 작업을 실행합니다. 빈 공간이나 섹션 제목을 오른쪽으로 밀면 메뉴가 열립니다.',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '일반 할 일',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _choice(
                      'right',
                      '왼쪽 → 오른쪽',
                      _value.right,
                      normalSwipeActions,
                      (a) => _value = _value.copyWith(right: a),
                    ),
                    _choice(
                      'left',
                      '오른쪽 → 왼쪽',
                      _value.left,
                      normalSwipeActions,
                      (a) => _value = _value.copyWith(left: a),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '휴지통',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _choice(
                      'trash-right',
                      '왼쪽 → 오른쪽',
                      _value.trashRight,
                      trashSwipeActions,
                      (a) => _value = _value.copyWith(trashRight: a),
                    ),
                    _choice(
                      'trash-left',
                      '오른쪽 → 왼쪽',
                      _value.trashLeft,
                      trashSwipeActions,
                      (a) => _value = _value.copyWith(trashLeft: a),
                    ),
                    const Text('삭제는 휴지통으로 이동합니다. 영구 삭제는 확인 후 실행합니다.'),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '저장 중…' : '저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

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

  Future<void> _save(String id, TaskSwipeAction action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final latest = await widget.repository.getSettings();
      final choices = latest.taskSwipes;
      final updated = switch (id) {
        'right' => choices.copyWith(right: action),
        'left' => choices.copyWith(left: action),
        'trash-right' => choices.copyWith(trashRight: action),
        _ => choices.copyWith(trashLeft: action),
      };
      final saved = await widget.repository.saveSettings(
        latest.copyWith(taskSwipes: updated),
      );
      widget.onSaved(saved);
      if (mounted) setState(() => _value = saved.taskSwipes);
    } catch (_) {
      if (mounted) setState(() => _error = '설정을 저장하지 못했습니다. 다시 선택해주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _choice(
    String id,
    bool right,
    TaskSwipeAction value,
    List<TaskSwipeAction> allowed,
  ) => Expanded(
    child: Column(
      children: [
        Icon(
          right ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          size: 20,
        ),
        const SizedBox(height: 6),
        InputDecorator(
          key: ValueKey('swipe-setting-$id'),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TaskSwipeAction>(
              value: value,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyMedium,
              selectedItemBuilder: (context) => [
                for (final action in allowed)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(action.label),
                    ),
                  ),
              ],
              items: [
                for (final action in allowed)
                  DropdownMenuItem(
                    value: action,
                    child: Text(action.label, maxLines: 1),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (action) {
                      if (action != null) _save(id, action);
                    },
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '스와이프 동작',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              const Text('할 일', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _choice('right', true, _value.right, normalSwipeActions),
                  const SizedBox(width: 12),
                  _choice('left', false, _value.left, normalSwipeActions),
                ],
              ),
              const SizedBox(height: 20),
              const Text('휴지통', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _choice(
                    'trash-right',
                    true,
                    _value.trashRight,
                    trashSwipeActions,
                  ),
                  const SizedBox(width: 12),
                  _choice(
                    'trash-left',
                    false,
                    _value.trashLeft,
                    trashSwipeActions,
                  ),
                ],
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
            ],
          ),
        ),
      ),
    ),
  );
}

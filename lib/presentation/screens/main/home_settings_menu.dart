import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../services/local_notification_service.dart';
import 'task_swipe_settings_sheet.dart';

enum _Setting { swipe, notificationTime, urgent }

Future<void> showHomeSettingsMenu({
  required BuildContext anchor,
  required AppSettings settings,
  required SettingsRepository repository,
  required LocalNotificationService notifications,
  required ValueChanged<AppSettings> onSaved,
}) async {
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(anchor).overlay!.context.findRenderObject()! as RenderBox;
  final offset = box.localToGlobal(const Offset(12, 0), ancestor: overlay);
  final selected = await showMenu<_Setting>(
    context: anchor,
    position: RelativeRect.fromRect(
      offset & Size.zero,
      Offset.zero & overlay.size,
    ),
    constraints: const BoxConstraints.tightFor(width: 208),
    items: [
      PopupMenuItem<_Setting>(
        height: 0,
        padding: EdgeInsets.zero,
        child: _SettingsMenu(
          settings: settings,
          repository: repository,
          notifications: notifications,
          onSaved: onSaved,
          onOpen: (context, choice) => Navigator.of(context).pop(choice),
        ),
      ),
    ],
  );
  if (selected == null || !anchor.mounted) return;
  AppSettings latest;
  try {
    latest = await repository.getSettings();
  } catch (_) {
    if (anchor.mounted) {
      ScaffoldMessenger.of(anchor).showSnackBar(
        const SnackBar(content: Text('설정을 불러오지 못했습니다. 다시 시도해주세요.')),
      );
    }
    return;
  }
  if (!anchor.mounted) return;
  if (selected == _Setting.swipe) {
    await showModalBottomSheet<void>(
      context: anchor,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => TaskSwipeSettingsSheet(
        settings: latest,
        repository: repository,
        onSaved: onSaved,
      ),
    );
    return;
  }
  final notification = selected == _Setting.notificationTime;
  await showModalBottomSheet<void>(
    context: anchor,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _NumberSettingSheet(
      title: notification ? '알림 시점' : '마감 임박',
      values: notification
          ? _notificationOffsets
          : [for (var day = 1; day <= 14; day++) day],
      selected: notification
          ? latest.defaultNotificationDays
          : latest.urgentDueDays,
      label: notification ? _notificationLabel : (day) => '$day일 이내',
      onSelected: (value) async {
        final current = await repository.getSettings();
        final saved = await repository.saveSettings(
          notification
              ? current.copyWith(
                  defaultNotificationDays: value,
                  defaultNotificationTime: 'relative',
                )
              : current.copyWith(urgentDueDays: value),
        );
        onSaved(saved);
      },
    ),
  );
}

class _SettingsMenu extends StatefulWidget {
  const _SettingsMenu({
    required this.settings,
    required this.repository,
    required this.notifications,
    required this.onSaved,
    required this.onOpen,
  });
  final AppSettings settings;
  final SettingsRepository repository;
  final LocalNotificationService notifications;
  final ValueChanged<AppSettings> onSaved;
  final void Function(BuildContext, _Setting) onOpen;
  @override
  State<_SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<_SettingsMenu> {
  late AppSettings _settings = widget.settings;
  bool _saving = false;
  Future<void> _toggleNotification() async {
    if (_saving) return;
    final enabled = !_settings.defaultNotificationEnabled;
    setState(() => _saving = true);
    try {
      // Preserve the existing default-notification policy and permission flow.
      if (enabled) await widget.notifications.requestPermission();
      final latest = await widget.repository.getSettings();
      final saved = await widget.repository.saveSettings(
        latest.copyWith(defaultNotificationEnabled: enabled),
      );
      widget.onSaved(saved);
      if (mounted) setState(() => _settings = saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('설정을 저장하지 못했습니다. 다시 시도해주세요.')),
          );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _entry(String title, _Setting choice) => InkWell(
    onTap: _saving ? null : () => widget.onOpen(context, choice),
    child: SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 208,
    child: Column(
      key: const ValueKey('home-settings-menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _entry('스와이프', _Setting.swipe),
        InkWell(
          onTap: _saving ? null : _toggleNotification,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Text('알림')),
                IconButton(
                  key: const ValueKey('settings-notification-toggle'),
                  tooltip: _settings.defaultNotificationEnabled
                      ? '알림 끄기'
                      : '알림 켜기',
                  color: _settings.defaultNotificationEnabled
                      ? AppTheme.primaryBlue
                      : AppTheme.muted,
                  icon: Icon(
                    _settings.defaultNotificationEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                  onPressed: _saving ? null : _toggleNotification,
                ),
              ],
            ),
          ),
        ),
        if (_settings.defaultNotificationEnabled)
          _entry('알림 시점', _Setting.notificationTime),
        _entry('마감 임박', _Setting.urgent),
      ],
    ),
  );
}

class _NumberSettingSheet extends StatefulWidget {
  const _NumberSettingSheet({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });
  final String title;
  final List<int> values;
  final int selected;
  final String Function(int) label;
  final Future<void> Function(int) onSelected;
  @override
  State<_NumberSettingSheet> createState() => _NumberSettingSheetState();
}

class _NumberSettingSheetState extends State<_NumberSettingSheet> {
  late int _saved = _closestIndex(widget.selected, widget.values);
  late int _index = _saved;
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSelected(widget.values[_index]);
      if (mounted) setState(() => _saved = _index);
    } catch (_) {
      if (mounted) {
        setState(() {
          _index = _saved;
          _error = '설정을 저장하지 못했습니다. 다시 설정해주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Text(
            widget.label(widget.values[_index]),
            textAlign: TextAlign.center,
          ),
          Slider(
            key: const ValueKey('settings-value-slider'),
            value: _index.toDouble(),
            min: 0,
            max: (widget.values.length - 1).toDouble(),
            divisions: widget.values.length - 1,
            label: widget.label(widget.values[_index]),
            onChanged: _saving
                ? null
                : (value) => setState(() => _index = value.round()),
            onChangeEnd: _saving ? null : (_) => _save(),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}

const _notificationOffsets = [0, 10, 20, 30, 60, 180, 360, 720, 1440, 4320];
int _closestIndex(int value, List<int> values) {
  var index = 0;
  for (var i = 1; i < values.length; i++) {
    if ((values[i] - value).abs() < (values[index] - value).abs()) index = i;
  }
  return index;
}

String _notificationLabel(int minutes) {
  if (minutes == 0) return '마감 시각';
  if (minutes < 60) return '마감 $minutes분 전';
  if (minutes < 1440) return '마감 ${minutes ~/ 60}시간 전';
  return '마감 ${minutes ~/ 1440}일 전';
}

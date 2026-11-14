import 'package:flutter/material.dart';

import '../../../data/models/task_models.dart';
import '../../../core/utils/list_defaults.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/services/personal_task_draft.dart';
import '../../widgets/task_metadata_picker.dart';

/// 오늘·주간 위젯이 함께 사용하는 등록 폼. 저장과 종료 처리는 외부에서 전달한다.
class WidgetTaskCreateScreen extends StatefulWidget {
  const WidgetTaskCreateScreen({
    super.key,
    required this.saveTask,
    required this.folderRepository,
    required this.onSaved,
    required this.onCancel,
    this.now = DateTime.now,
  });

  final Future<void> Function(Task task, List<Tag> newTags) saveTask;
  final FolderRepository folderRepository;
  final Future<void> Function() onSaved;
  final VoidCallback onCancel;
  final DateTime Function() now;

  @override
  State<WidgetTaskCreateScreen> createState() => _WidgetTaskCreateScreenState();
}

class _WidgetTaskCreateScreenState extends State<WidgetTaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String _selectedListId = inboxListId;
  late DateTime _due;
  List<Folder> _lists = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = widget.now();
    _due = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _loadLists();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await widget.folderRepository.getFolders();
      if (mounted) {
        setState(() {
          _lists = lists.where((list) => list.archivedAt == null).toList()
            ..sort((a, b) {
              if (a.id == b.id) return 0;
              if (a.id == inboxListId) return -1;
              if (b.id == inboxListId) return 1;
              return a.sortOrder.compareTo(b.sortOrder);
            });
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '목록을 불러오지 못했습니다. 다시 시도해주세요.';
        });
      }
    }
  }

  // 날짜만 바꾸고 사용자가 선택한 마감 시간은 유지한다.
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: _due.isBefore(DateTime(2020)) ? _due : DateTime(2020),
      lastDate: _due.isAfter(DateTime(2035, 12, 31))
          ? _due
          : DateTime(2035, 12, 31),
    );
    if (date != null && mounted) {
      setState(() {
        _due = DateTime(
          date.year,
          date.month,
          date.day,
          _due.hour,
          _due.minute,
        );
      });
    }
  }

  // 시간만 바꾸고 사용자가 선택한 마감 날짜는 유지한다.
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (time != null && mounted) {
      setState(() {
        _due = DateTime(
          _due.year,
          _due.month,
          _due.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  // 기존 저장 경로에 선택한 목록을 전달하고 중복 저장을 차단한다.
  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.saveTask(
        personalTaskDraft(
          title: _title.text,
          now: widget.now(),
          dueDate: _due,
          listId: _selectedListId,
        ),
        const [],
      );
    } catch (_) {
      // 저장 실패 시 입력과 선택을 유지하고 재시도를 허용한다.
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '일정을 저장하지 못했습니다. 입력 내용을 확인하고 다시 시도해주세요.';
        });
      }
      return;
    }
    // DB 저장 후에는 위젯 갱신이 실패해도 중복 등록되지 않도록 저장 버튼을 잠근다.
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // 저장 중이 아닐 때 뒤로가기는 저장 없이 팝업을 종료한다.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) widget.onCancel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '빠른 일정 등록',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _title,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: '일정 제목',
                              hintText: '제목을 입력해주세요',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? '제목을 입력해주세요.'
                                : null,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              '마감 날짜  ${_due.year}.${_due.month.toString().padLeft(2, '0')}.${_due.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              '마감 시간  ${_due.hour.toString().padLeft(2, '0')}:${_due.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_loading)
                            const Center(child: CircularProgressIndicator())
                          else
                            AbsorbPointer(
                              absorbing: _saving,
                              child: FolderPickerSection(
                                folders: _lists,
                                selectedId: _selectedListId,
                                onSelect: (list) => setState(() {
                                  _selectedListId = list?.id ?? inboxListId;
                                }),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            if (_lists.isEmpty)
                              TextButton(
                                onPressed: _saving ? null : _loadLists,
                                child: const Text('목록 다시 불러오기'),
                              ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _saving ? null : widget.onCancel,
                                child: const Text('취소'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _saving || _loading || _lists.isEmpty
                                    ? null
                                    : _save,
                                child: Text(_saving ? '저장 중…' : '저장'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

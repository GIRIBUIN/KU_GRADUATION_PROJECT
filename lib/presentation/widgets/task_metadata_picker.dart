import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';

const metadataColorOptions = [
  '#EF4444',
  '#F97316',
  '#EAB308',
  '#22C55E',
  '#3B82F6',
  '#8B5CF6',
  '#6B7280',
];

class TagDraft {
  const TagDraft({required this.name, required this.color, this.folderId});

  final String name;
  final String color;
  final String? folderId;
}

class FolderDraft {
  const FolderDraft({
    required this.name,
    required this.color,
    this.parentFolderId,
  });

  final String name;
  final String color;
  final String? parentFolderId;
}

class TagPickerSection extends StatelessWidget {
  const TagPickerSection({
    super.key,
    required this.tags,
    required this.selectedIds,
    required this.onToggle,
    required this.onAdd,
  });

  final List<Tag> tags;
  final Set<String> selectedIds;
  final ValueChanged<Tag> onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _MetadataPickerFrame(
      title: '태그',
      addTooltip: '태그 추가',
      onAdd: onAdd,
      child: tags.isEmpty
          ? const _EmptyPickerText(message: '태그가 없습니다. + 버튼으로 추가할 수 있습니다.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tag in tags) ...[
                    _TagChoiceChip(
                      tag: tag,
                      selected: selectedIds.contains(tag.id),
                      onTap: () => onToggle(tag),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
    );
  }
}

class FolderPickerSection extends StatelessWidget {
  const FolderPickerSection({
    super.key,
    required this.folders,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  final List<Folder> folders;
  final String? selectedId;
  final ValueChanged<Folder?> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _MetadataPickerFrame(
      title: '폴더',
      addTooltip: '폴더 추가',
      onAdd: onAdd,
      child: folders.isEmpty
          ? const _EmptyPickerText(message: '폴더가 없습니다. + 버튼으로 추가할 수 있습니다.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ClearFolderChip(
                    selected: selectedId == null,
                    onTap: () => onSelect(null),
                  ),
                  const SizedBox(width: 8),
                  for (final folder in folders) ...[
                    _FolderChoiceChip(
                      folder: folder,
                      selected: selectedId == folder.id,
                      onTap: () => onSelect(folder),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
    );
  }
}

class TaskMetadataChips extends StatelessWidget {
  const TaskMetadataChips({
    super.key,
    required this.tags,
    required this.folders,
    this.maxVisible = 2,
  });

  final List<Tag> tags;
  final List<Folder> folders;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final folder in folders)
        _SmallMetadataChip(
          label: folder.name,
          color: colorFromHex(folder.color, fallback: AppTheme.successGreen),
          icon: Icons.folder_rounded,
        ),
      for (final tag in tags)
        _SmallMetadataChip(
          label: tag.name,
          color: colorFromHex(tag.color),
          icon: Icons.circle,
        ),
    ];
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = chips.take(maxVisible).toList(growable: false);
    final hiddenCount = chips.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final chip in visible) ...[chip, const SizedBox(width: 6)],
        if (hiddenCount > 0) _SmallMetadataChip(label: '+$hiddenCount'),
      ],
    );
  }
}

Future<TagDraft?> showTagCreateDialog(
  BuildContext context, {
  List<Folder> folders = const [],
}) {
  return showDialog<TagDraft>(
    context: context,
    builder: (_) => _TagCreateDialog(folders: folders),
  );
}

Future<FolderDraft?> showFolderCreateDialog(
  BuildContext context, {
  List<Folder> folders = const [],
}) {
  return showDialog<FolderDraft>(
    context: context,
    builder: (_) => _FolderCreateDialog(folders: folders),
  );
}

Color colorFromHex(String? value, {Color fallback = AppTheme.primaryBlue}) {
  final normalized = normalizeHex(value);
  if (!isValidHexColor(normalized)) {
    return fallback;
  }
  return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
}

String normalizeHex(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }
  final withHash = trimmed.startsWith('#') ? trimmed : '#$trimmed';
  return withHash.toUpperCase();
}

bool isValidHexColor(String value) {
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(value);
}

class _MetadataPickerFrame extends StatelessWidget {
  const _MetadataPickerFrame({
    required this.title,
    required this.addTooltip,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final String addTooltip;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              tooltip: addTooltip,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ],
    );
  }
}

class _TagChoiceChip extends StatelessWidget {
  const _TagChoiceChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final Tag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(tag.color);
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(Icons.circle, color: color, size: 12),
      label: Text(tag.name),
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      side: BorderSide(
        color: selected ? AppTheme.primaryBlue : color.withValues(alpha: 0.35),
      ),
    );
  }
}

class _FolderChoiceChip extends StatelessWidget {
  const _FolderChoiceChip({
    required this.folder,
    required this.selected,
    required this.onTap,
  });

  final Folder folder;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(folder.color, fallback: AppTheme.successGreen);
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(Icons.folder_rounded, color: color, size: 18),
      label: Text(folder.name),
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      side: BorderSide(
        color: selected ? AppTheme.primaryBlue : color.withValues(alpha: 0.35),
      ),
    );
  }
}

class _ClearFolderChip extends StatelessWidget {
  const _ClearFolderChip({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: const Icon(Icons.block_rounded, size: 16),
      label: const Text('없음'),
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      side: BorderSide(color: selected ? AppTheme.primaryBlue : AppTheme.line),
    );
  }
}

class _SmallMetadataChip extends StatelessWidget {
  const _SmallMetadataChip({required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPickerText extends StatelessWidget {
  const _EmptyPickerText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppTheme.muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TagCreateDialog extends StatefulWidget {
  const _TagCreateDialog({required this.folders});

  final List<Folder> folders;

  @override
  State<_TagCreateDialog> createState() => _TagCreateDialogState();
}

class _TagCreateDialogState extends State<_TagCreateDialog> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: '#3B82F6');
  String? _folderId;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('태그 추가'),
      content: SingleChildScrollView(
        child: _MetadataFormBody(
          nameController: _nameController,
          colorController: _colorController,
          nameLabel: '태그 이름',
          initialColor: AppTheme.primaryBlue,
          errorText: _errorText,
          onColorChanged: () => setState(() => _errorText = null),
          extra: [
            if (widget.folders.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _folderId,
                decoration: const InputDecoration(labelText: '폴더 위치'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('루트'),
                  ),
                  for (final folder in widget.folders)
                    DropdownMenuItem<String?>(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _folderId = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final color = normalizeHex(_colorController.text);
    if (name.isEmpty) {
      setState(() => _errorText = null);
      return;
    }
    if (!isValidHexColor(color)) {
      setState(() => _errorText = '#RRGGBB 형식으로 입력해주세요.');
      return;
    }
    Navigator.of(
      context,
    ).pop(TagDraft(name: name, color: color, folderId: _folderId));
  }
}

class _FolderCreateDialog extends StatefulWidget {
  const _FolderCreateDialog({required this.folders});

  final List<Folder> folders;

  @override
  State<_FolderCreateDialog> createState() => _FolderCreateDialogState();
}

class _FolderCreateDialogState extends State<_FolderCreateDialog> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: '#22C55E');
  String? _parentFolderId;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('폴더 추가'),
      content: SingleChildScrollView(
        child: _MetadataFormBody(
          nameController: _nameController,
          colorController: _colorController,
          nameLabel: '폴더 이름',
          initialColor: AppTheme.successGreen,
          errorText: _errorText,
          icon: Icons.folder_rounded,
          onColorChanged: () => setState(() => _errorText = null),
          extra: [
            if (widget.folders.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _parentFolderId,
                decoration: const InputDecoration(labelText: '상위 폴더'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('없음'),
                  ),
                  for (final folder in widget.folders)
                    DropdownMenuItem<String?>(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _parentFolderId = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final color = normalizeHex(_colorController.text);
    if (name.isEmpty) {
      setState(() => _errorText = null);
      return;
    }
    if (!isValidHexColor(color)) {
      setState(() => _errorText = '#RRGGBB 형식으로 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(
      FolderDraft(name: name, color: color, parentFolderId: _parentFolderId),
    );
  }
}

class _MetadataFormBody extends StatelessWidget {
  const _MetadataFormBody({
    required this.nameController,
    required this.colorController,
    required this.nameLabel,
    required this.initialColor,
    required this.errorText,
    required this.onColorChanged,
    this.icon,
    this.extra = const [],
  });

  final TextEditingController nameController;
  final TextEditingController colorController;
  final String nameLabel;
  final Color initialColor;
  final String? errorText;
  final VoidCallback onColorChanged;
  final IconData? icon;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final selectedColor = colorFromHex(
      colorController.text,
      fallback: initialColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: nameLabel),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        const Text('색상', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in metadataColorOptions)
              _ColorOptionButton(
                color: colorFromHex(color),
                selected: normalizeHex(colorController.text) == color,
                onTap: () {
                  colorController.text = color;
                  onColorChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: colorController,
          decoration: InputDecoration(
            labelText: '직접 입력',
            hintText: '#3B82F6',
            errorText: errorText,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: icon == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 18, height: 18),
                    )
                  : Icon(icon, color: selectedColor, size: 22),
            ),
          ),
          onChanged: (_) => onColorChanged(),
        ),
        ...extra,
      ],
    );
  }
}

class _ColorOptionButton extends StatelessWidget {
  const _ColorOptionButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}

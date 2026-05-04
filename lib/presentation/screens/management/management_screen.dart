import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/task_models.dart';
import '../../widgets/section_title.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const SectionTitle(title: '태그'),
          Card(
            child: Column(
              children: [
                for (final tag in MockData.tags) ...[
                  _TagManagementRow(tag: tag),
                  if (tag != MockData.tags.last)
                    const Divider(height: 1, indent: 20, endIndent: 20),
                ],
                const Divider(height: 1, indent: 20, endIndent: 20),
                _AddRow(label: '태그 추가', onTap: () {}),
              ],
            ),
          ),
          const SectionTitle(title: '폴더'),
          Card(
            child: Column(
              children: [
                for (final folder in MockData.folders) ...[
                  _FolderRow(folder: folder),
                  if (folder != MockData.folders.last)
                    const Divider(height: 1, indent: 20, endIndent: 20),
                ],
                const Divider(height: 1, indent: 20, endIndent: 20),
                _AddRow(label: '폴더 추가', onTap: () {}),
              ],
            ),
          ),
          const SectionTitle(title: '정리'),
          Card(
            child: Column(
              children: [
                _CleanupRow(
                  icon: Icons.delete_outline_rounded,
                  label: '삭제된 작업',
                  value: '2개',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _CleanupRow(
                  icon: Icons.block_rounded,
                  label: '가져오지 않을 e-campus 항목',
                  value: '3개',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagManagementRow extends StatelessWidget {
  const _TagManagementRow({required this.tag});

  final TaskTag tag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 18),
            Text(
              tag.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '기본 우선순위 ${_priorityLabel(tag.defaultPriority)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => '높음',
      TaskPriority.medium => '보통',
      TaskPriority.low => '낮음',
    };
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folder});

  final TaskFolder folder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            const Icon(
              Icons.folder_rounded,
              color: AppTheme.successGreen,
              size: 30,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                folder.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${folder.count}개',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _CleanupRow extends StatelessWidget {
  const _CleanupRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF3F4F6),
              child: Icon(icon, color: AppTheme.muted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.successGreen,
          side: const BorderSide(color: AppTheme.successGreen),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

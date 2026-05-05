import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/task_models.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/task_checkbox.dart';

class SyncResultScreen extends StatelessWidget {
  const SyncResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('동기화 결과')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const _SyncSummary(),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: _CountTitle(title: '가져올 항목', count: '4'),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.successGreen,
                  side: const BorderSide(color: AppTheme.successGreen),
                ),
                child: const Text('모두 선택'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final candidate in MockData.syncImportCandidates) ...[
            _SyncCandidateCard(candidate: candidate),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          const _ExcludedHeader(),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final candidate in MockData.syncExcludedCandidates) ...[
                  _SyncCandidateRow(candidate: candidate),
                  if (candidate != MockData.syncExcludedCandidates.last)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('선택 항목 가져오기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sync_rounded,
            color: AppTheme.successGreen,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '새 항목 3개',
                  style: TextStyle(color: AppTheme.successGreen),
                ),
                TextSpan(text: ', 업데이트 후보 '),
                TextSpan(
                  text: '1개',
                  style: TextStyle(color: AppTheme.warningOrange),
                ),
                TextSpan(text: ' 감지'),
              ],
            ),
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _CountTitle extends StatelessWidget {
  const _CountTitle({required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 9),
        CircleAvatar(
          radius: 15,
          backgroundColor: AppTheme.successGreen.withValues(alpha: 0.14),
          child: Text(
            count,
            style: const TextStyle(
              color: AppTheme.successGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncCandidateCard extends StatelessWidget {
  const _SyncCandidateCard({required this.candidate});

  final SyncCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            TaskCheckbox(isChecked: candidate.isSelected, size: 30),
            const SizedBox(width: 14),
            Expanded(child: _CandidateText(candidate: candidate)),
            AppBadge(
              label: candidate.dueLabel,
              color: candidate.statusColor,
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(width: 10),
            AppBadge(
              label: candidate.statusLabel,
              color: candidate.statusColor,
              filled: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCandidateRow extends StatelessWidget {
  const _SyncCandidateRow({required this.candidate});

  final SyncCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          TaskCheckbox(isChecked: candidate.isSelected, size: 28),
          const SizedBox(width: 14),
          Expanded(child: _CandidateText(candidate: candidate)),
          AppBadge(
            label: candidate.dueLabel,
            color: candidate.statusColor,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 8),
          AppBadge(label: candidate.statusLabel, color: candidate.statusColor),
        ],
      ),
    );
  }
}

class _CandidateText extends StatelessWidget {
  const _CandidateText({required this.candidate});

  final SyncCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          candidate.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              color: AppTheme.muted,
              size: 18,
            ),
            SizedBox(width: 5),
            Text(
              'e-campus',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (candidate.changeNote != null) ...[
          const SizedBox(height: 6),
          Text(
            candidate.changeNote!,
            style: const TextStyle(
              color: AppTheme.warningOrange,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExcludedHeader extends StatelessWidget {
  const _ExcludedHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '가져오지 않을 항목',
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Expanded(child: Divider()),
        IconButton(
          tooltip: '접기',
          onPressed: () {},
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
      ],
    );
  }
}

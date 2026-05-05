import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../widgets/section_title.dart';
import '../../widgets/task_widgets.dart';
import '../task/sync_result_screen.dart';
import '../task/task_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '5월 4일 월요일',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '동기화',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SyncResultScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync_rounded),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: '설정',
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SummaryPanel(),
            const SectionTitle(title: '오늘 할 일'),
            for (final task in MockData.todayTasks) ...[
              TaskCard(
                task: task,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskEditScreen(task: task),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            const SectionTitle(title: '마감 임박'),
            Card(
              child: Column(
                children: [
                  for (final task in MockData.upcomingTasks) ...[
                    InlineTaskRow(
                      task: task,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TaskEditScreen(task: task),
                          ),
                        );
                      },
                    ),
                    if (task != MockData.upcomingTasks.last)
                      const Divider(height: 1, indent: 12, endIndent: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync_rounded, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text(
                  '마지막 동기화: 오늘 09:20',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        tooltip: '개인 할 일 추가',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TaskEditScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: const [
            Expanded(
              child: _SummaryMetric(
                icon: Icons.event_available_outlined,
                label: '오늘 할 일',
                value: '4',
                color: AppTheme.successGreen,
              ),
            ),
            _PanelDivider(),
            Expanded(
              child: _SummaryMetric(
                icon: Icons.schedule_rounded,
                label: '마감 임박',
                value: '7',
                color: AppTheme.warningOrange,
              ),
            ),
            _PanelDivider(),
            Expanded(
              child: _SummaryMetric(
                icon: Icons.assignment_outlined,
                label: '미완료',
                value: '12',
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 74, color: AppTheme.line);
  }
}

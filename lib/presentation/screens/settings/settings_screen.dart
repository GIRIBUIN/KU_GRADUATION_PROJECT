import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/section_title.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: const [
          SectionTitle(title: 'e-campus 연동'),
          _SettingsGroup(
            children: [
              _SwitchRow(
                icon: Icons.lock_outline_rounded,
                title: '계정 정보 저장',
                value: true,
                color: AppTheme.successGreen,
              ),
              _SwitchRow(
                icon: Icons.sync_rounded,
                title: '앱 실행 시 자동 동기화',
                value: true,
                color: AppTheme.successGreen,
              ),
              _NavigationRow(
                icon: Icons.person_remove_outlined,
                title: '저장된 계정 삭제',
              ),
              _StaticRow(
                icon: Icons.schedule_rounded,
                title: '마지막 동기화: 오늘 09:20',
              ),
            ],
          ),
          SectionTitle(title: '알림'),
          _SettingsGroup(
            children: [
              _NavigationRow(
                icon: Icons.notifications_none_rounded,
                title: '기본 알림',
                value: '마감 1일 전 오전 9시',
                color: AppTheme.primaryBlue,
              ),
              _NavigationRow(
                icon: Icons.timelapse_rounded,
                title: '마감 임박 기준',
                value: '3일 이내',
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
          SectionTitle(title: '보안'),
          _SettingsGroup(
            children: [
              _SecurityNotice(),
              _NavigationRow(
                icon: Icons.delete_sweep_outlined,
                title: '세션/쿠키 정리',
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
          SectionTitle(title: '위젯'),
          _SettingsGroup(
            children: [
              _NavigationRow(
                icon: Icons.widgets_outlined,
                title: '표시 기준',
                value: '오늘 할 일 + 마감 임박',
                color: AppTheme.successGreen,
              ),
              _NavigationRow(
                icon: Icons.format_list_bulleted_rounded,
                title: '표시 개수',
                value: '3개',
                color: AppTheme.successGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final child in children) ...[
            child,
            if (child != children.last)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 23,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final bool value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Switch(value: value, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    this.value,
    this.color = AppTheme.muted,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _IconBubble(icon: icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
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

class _StaticRow extends StatelessWidget {
  const _StaticRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: AppTheme.muted),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(
            icon: Icons.verified_user_outlined,
            color: AppTheme.primaryBlue,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              '계정 정보는 기기 내 보안 저장소에만 저장됩니다.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

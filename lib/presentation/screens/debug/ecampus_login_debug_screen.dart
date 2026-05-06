import 'package:flutter/material.dart';

import '../../../data/services/ecampus_auth_service.dart';
import '../login/ecampus_login_webview_screen.dart';

class EcampusLoginDebugScreen extends StatefulWidget {
  const EcampusLoginDebugScreen({super.key});

  @override
  State<EcampusLoginDebugScreen> createState() =>
      _EcampusLoginDebugScreenState();
}

class _EcampusLoginDebugScreenState extends State<EcampusLoginDebugScreen> {
  EcampusSession? _session;
  String _status = '대기 중';

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final hasSessionId = session?.cookies['JSESSIONID']?.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('e-campus 로그인 확인')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.account_balance_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'e-campus 로그인 세션 테스트',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'WebView 로그인 후 세션 쿠키가 앱으로 돌아오는지만 확인합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _openLoginWebView,
              icon: const Icon(Icons.login_rounded),
              label: const Text('e-campus 로그인 테스트'),
            ),
            const SizedBox(height: 24),
            _ResultRow(label: '로그인 상태', value: _status),
            _ResultRow(
              label: '세션 생성 시각',
              value: session?.createdAt.toLocal().toString() ?? '-',
            ),
            _ResultRow(
              label: '쿠키 개수',
              value: '${session?.cookies.length ?? 0}',
            ),
            _ResultRow(
              label: 'JSESSIONID',
              value: hasSessionId == true ? '있음' : '없음',
            ),
            _ResultRow(label: '마지막 URL', value: session?.lastUrl ?? '-'),
          ],
        ),
      ),
    );
  }

  Future<void> _openLoginWebView() async {
    final session = await Navigator.of(context).push<EcampusSession>(
      MaterialPageRoute(
        builder: (_) => const EcampusLoginWebViewScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _status = session == null ? '취소됨' : '성공';
    });
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

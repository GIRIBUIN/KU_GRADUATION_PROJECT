import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/ecampus_models.dart';
import '../../../data/services/default_ecampus_todo_service.dart';
import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/services/ecampus_todo_parser.dart';
import '../../../data/services/http_ecampus_todo_client.dart';
import '../login/ecampus_login_webview_screen.dart';

class EcampusLoginDebugScreen extends StatefulWidget {
  const EcampusLoginDebugScreen({super.key});

  @override
  State<EcampusLoginDebugScreen> createState() =>
      _EcampusLoginDebugScreenState();
}

class _EcampusLoginDebugScreenState extends State<EcampusLoginDebugScreen> {
  late final http.Client _httpClient;
  late final DefaultEcampusTodoService _todoService;

  EcampusSession? _session;
  String _status = '대기 중';
  String _todoStatus = '대기 중';
  EcampusTodoParseResult? _parseResult;
  int? _htmlLength;
  String? _errorMessage;
  var _isFetchingTodo = false;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    _todoService = DefaultEcampusTodoService(
      client: HttpEcampusTodoClient(httpClient: _httpClient),
      parser: const EcampusTodoParser(),
    );
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final parseResult = _parseResult;
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
              'Android WebView에서 로그인 세션 쿠키와 todo HTML 요청을 수동으로 확인합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _openLoginWebView,
              icon: const Icon(Icons.login_rounded),
              label: const Text('e-campus 로그인 테스트'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: session == null || _isFetchingTodo ? null : _fetchTodo,
              icon: _isFetchingTodo
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isFetchingTodo ? 'todo 가져오는 중' : 'todo 가져오기'),
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
            const Divider(height: 32),
            _ResultRow(label: 'todo 상태', value: _todoStatus),
            _ResultRow(label: 'HTML 길이', value: '${_htmlLength ?? 0}'),
            _ResultRow(
              label: '파싱된 todo',
              value: '${parseResult?.tasks.length ?? 0}',
            ),
            _ResultRow(
              label: '파싱 실패',
              value: '${parseResult?.failures.length ?? 0}',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (parseResult != null && parseResult.tasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'todo 미리보기',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final task in parseResult.tasks.take(5))
                _TodoPreviewItem(task: task),
            ],
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
      _todoStatus = '대기 중';
      _parseResult = null;
      _htmlLength = null;
      _errorMessage = null;
    });
  }

  Future<void> _fetchTodo() async {
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() {
      _isFetchingTodo = true;
      _todoStatus = '요청 중';
      _parseResult = null;
      _htmlLength = null;
      _errorMessage = null;
    });

    try {
      final html = await _todoService.fetchTodoHtml(session);
      final parseResult = _todoService.parseTodoHtml(html);

      if (!mounted) {
        return;
      }

      setState(() {
        _todoStatus = '성공';
        _htmlLength = html.length;
        _parseResult = parseResult;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _todoStatus = '실패';
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingTodo = false;
        });
      }
    }
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

class _TodoPreviewItem extends StatelessWidget {
  const _TodoPreviewItem({required this.task});

  final ParsedEcampusTask task;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(task.course),
            const SizedBox(height: 4),
            Text(task.dueLabel ?? '-'),
          ],
        ),
      ),
    );
  }
}

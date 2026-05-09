import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/default_ecampus_sync_service.dart';
import '../../../data/services/default_ecampus_todo_service.dart';
import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/services/ecampus_sync_apply_service.dart';
import '../../../data/services/ecampus_sync_classifier.dart';
import '../../../data/services/ecampus_sync_flow_service.dart';
import '../../../data/services/ecampus_todo_parser.dart';
import '../../../data/services/http_ecampus_todo_client.dart';
import '../login/ecampus_login_webview_screen.dart';
import 'ecampus_sync_preview_screen.dart';

class EcampusSyncProgressScreen extends StatefulWidget {
  const EcampusSyncProgressScreen({
    super.key,
    required this.taskRepository,
    this.initialSession,
    this.onSessionChanged,
  });

  final TaskRepository taskRepository;
  final EcampusSession? initialSession;
  final ValueChanged<EcampusSession?>? onSessionChanged;

  @override
  State<EcampusSyncProgressScreen> createState() =>
      _EcampusSyncProgressScreenState();
}

class _EcampusSyncProgressScreenState extends State<EcampusSyncProgressScreen> {
  late final http.Client _httpClient;
  late final DefaultEcampusSyncFlowService _flowService;

  EcampusSession? _session;
  _SyncStep _currentStep = _SyncStep.login;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _httpClient = http.Client();
    final todoService = DefaultEcampusTodoService(
      client: HttpEcampusTodoClient(httpClient: _httpClient),
      parser: const EcampusTodoParser(),
    );
    _flowService = DefaultEcampusSyncFlowService(
      taskRepository: widget.taskRepository,
      syncService: DefaultEcampusSyncService(
        todoService: todoService,
        classifier: const EcampusSyncClassifier(),
      ),
      applyService: DefaultEcampusSyncApplyService(
        taskRepository: widget.taskRepository,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('e-campus 동기화')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text(
              '동기화 상태',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final step in _SyncStep.values) ...[
              _SyncStepTile(
                step: step,
                state: _stateFor(step),
                isCurrent: step == _currentStep,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 24),
            Card(
              color: AppTheme.primaryBlue.withValues(alpha: 0.06),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: AppTheme.primaryBlue,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '로그인이 필요하면 WebView로 이동합니다.',
                      style: TextStyle(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      '아이디와 비밀번호는 저장하지 않고, 로그인 세션으로만 todo를 가져옵니다.',
                      style: TextStyle(color: AppTheme.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 18),
              Card(
                color: AppTheme.dangerRed.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '동기화 실패',
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _startSync,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startSync() async {
    setState(() {
      _errorMessage = null;
      _currentStep = _SyncStep.login;
    });

    try {
      var session = _session;
      session ??= await Navigator.of(context).push<EcampusSession>(
        MaterialPageRoute(
          builder: (_) => const EcampusLoginWebViewScreen(),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) {
        return;
      }

      if (session == null) {
        setState(() {
          _errorMessage = '로그인이 취소되었습니다.';
        });
        return;
      }

      _session = session;
      widget.onSessionChanged?.call(session);

      setState(() {
        _currentStep = _SyncStep.fetchTodo;
      });

      final result = await _flowService.preview(session: session);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentStep = _SyncStep.compare;
      });

      final didImport = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EcampusSyncPreviewScreen(
            syncResult: result,
            syncFlowService: _flowService,
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(didImport == true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        if (error is EcampusSessionExpiredException) {
          _session = null;
          widget.onSessionChanged?.call(null);
        }
      });
    }
  }

  _SyncStepState _stateFor(_SyncStep step) {
    if (_errorMessage != null && step == _currentStep) {
      return _SyncStepState.failed;
    }
    if (step.index < _currentStep.index) {
      return _SyncStepState.done;
    }
    if (step == _currentStep) {
      return _SyncStepState.running;
    }
    return _SyncStepState.waiting;
  }
}

class _SyncStepTile extends StatelessWidget {
  const _SyncStepTile({
    required this.step,
    required this.state,
    required this.isCurrent,
  });

  final _SyncStep step;
  final _SyncStepState state;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _SyncStepState.done => AppTheme.successGreen,
      _SyncStepState.running => AppTheme.primaryBlue,
      _SyncStepState.failed => AppTheme.dangerRed,
      _SyncStepState.waiting => AppTheme.muted,
    };
    final trailing = switch (state) {
      _SyncStepState.done => '완료',
      _SyncStepState.running => '진행 중',
      _SyncStepState.failed => '실패',
      _SyncStepState.waiting => '대기',
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: color,
          child: state == _SyncStepState.done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : null,
        ),
        title: Text(
          step.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        trailing: isCurrent && state == _SyncStepState.running
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                trailing,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

enum _SyncStep {
  login('로그인 확인'),
  fetchTodo('todo 가져오기'),
  parse('HTML 파싱'),
  compare('기존 작업 비교');

  const _SyncStep(this.label);

  final String label;
}

enum _SyncStepState { waiting, running, done, failed }

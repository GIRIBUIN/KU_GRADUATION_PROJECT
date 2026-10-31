import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_models.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/default_ecampus_sync_service.dart';
import '../../../data/services/default_ecampus_todo_service.dart';
import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/services/ecampus_sync_apply_service.dart';
import '../../../data/services/ecampus_sync_classifier.dart';
import '../../../data/services/ecampus_sync_flow_service.dart';
import '../../../data/services/ecampus_todo_parser.dart';
import '../../../data/services/http_ecampus_todo_client.dart';
import '../../../data/services/http_ecampus_auth_service.dart';
import '../../services/ecampus_notification_updater.dart';
import '../../services/in_app_webview_ecampus_cookie_store.dart';
import '../../services/local_notification_service.dart';
import '../login/ecampus_login_webview_screen.dart';
import 'ecampus_sync_preview_screen.dart';

class EcampusSyncProgressScreen extends StatefulWidget {
  const EcampusSyncProgressScreen({
    super.key,
    required this.taskRepository,
    required this.tagRepository,
    required this.folderRepository,
    required this.settingsRepository,
    required this.notificationRepository,
    required this.localNotificationService,
    this.onSessionChanged,
    this.authService,
    this.syncFlowService,
    this.openLogin,
    this.onOpenTask,
    this.onOrganizeUnassigned,
  });

  final TaskRepository taskRepository;
  final TagRepository tagRepository;
  final FolderRepository folderRepository;
  final SettingsRepository settingsRepository;
  final NotificationRepository notificationRepository;
  final LocalNotificationService localNotificationService;
  final ValueChanged<EcampusSession?>? onSessionChanged;
  final EcampusAuthService? authService;
  final EcampusSyncFlowService? syncFlowService;
  final Future<EcampusSession?> Function(BuildContext context)? openLogin;
  final Future<void> Function(Task)? onOpenTask;
  final Future<List<Task>> Function(Iterable<String>)? onOrganizeUnassigned;

  @override
  State<EcampusSyncProgressScreen> createState() =>
      _EcampusSyncProgressScreenState();
}

class _EcampusSyncProgressScreenState extends State<EcampusSyncProgressScreen> {
  late final http.Client _httpClient;
  late final EcampusSyncFlowService _flowService;

  EcampusSession? _session;
  _SyncStep _currentStep = _SyncStep.login;
  String? _errorMessage;
  var _isSyncing = false;
  Future<void>? _cleanup;
  var _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    final todoService = DefaultEcampusTodoService(
      client: HttpEcampusTodoClient(httpClient: _httpClient),
      parser: const EcampusTodoParser(),
    );
    final notificationUpdater = EcampusNotificationUpdater(
      repository: widget.notificationRepository,
      notifications: widget.localNotificationService,
    );
    _flowService =
        widget.syncFlowService ??
        DefaultEcampusSyncFlowService(
          taskRepository: widget.taskRepository,
          syncService: DefaultEcampusSyncService(
            todoService: todoService,
            classifier: const EcampusSyncClassifier(),
          ),
          applyService: DefaultEcampusSyncApplyService(
            taskRepository: widget.taskRepository,
            tagRepository: widget.tagRepository,
            folderRepository: widget.folderRepository,
            settingsRepository: widget.settingsRepository,
            afterTaskCommit: notificationUpdater.afterCommit,
            onPostCommitError: (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '일정은 저장했지만 알림 예약을 갱신하지 못했습니다. 알림 설정을 확인해주세요.',
                    ),
                  ),
                );
              }
            },
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }

  @override
  void dispose() {
    unawaited(_finishSession());
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_cancelAndClose());
      },
      child: Scaffold(
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
                          onPressed: _isSyncing ? null : _startSync,
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
      ),
    );
  }

  Future<void> _startSync() async {
    if (_isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
      _currentStep = _SyncStep.login;
    });
    _cleanup = null;
    bool? didChange;
    var shouldClose = false;

    try {
      // Every attempt starts with an explicit login, including retries.
      await _withAuth((auth) => auth.clearSession());
      if (!mounted || _cancelRequested) return;
      final session = widget.openLogin != null
          ? await widget.openLogin!(context)
          : await Navigator.of(context).push<EcampusSession>(
              MaterialPageRoute(
                builder: (_) => const EcampusLoginWebViewScreen(),
                fullscreenDialog: true,
              ),
            );

      _session = session;
      if (!mounted || _cancelRequested) {
        // A login result delivered after disposal still needs cleanup.
        _cleanup = null;
        return;
      }

      if (session == null) {
        setState(() {
          _errorMessage = '로그인이 취소되었습니다.';
        });
        return;
      }

      widget.onSessionChanged?.call(session);

      setState(() {
        _currentStep = _SyncStep.fetchTodo;
      });

      final result = await _flowService.preview(session: session);

      if (!mounted || _cancelRequested) {
        return;
      }

      setState(() {
        _currentStep = _SyncStep.compare;
      });

      didChange = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EcampusSyncPreviewScreen(
            onOrganizeUnassigned: widget.onOrganizeUnassigned,
            onOpenTask: widget.onOpenTask,
            syncResult: result,
            syncFlowService: _flowService,
            onApplyFinished: _finishSession,
            folderRepository: widget.folderRepository,
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      shouldClose = true;
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      await _finishSession();
      if (mounted && !_cancelRequested) {
        setState(() => _isSyncing = false);
        if (shouldClose) Navigator.of(context).pop(didChange == true);
      }
    }
  }

  Future<void> _cancelAndClose() async {
    if (_cancelRequested) return;
    _cancelRequested = true;
    _httpClient.close();
    await _finishSession();
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _withAuth(
    Future<void> Function(EcampusAuthService) action,
  ) async {
    final client = http.Client();
    try {
      await action(
        widget.authService ??
            HttpEcampusAuthService(
              httpClient: client,
              cookieStore: const InAppWebViewEcampusCookieStore(),
            ),
      );
    } finally {
      client.close();
    }
  }

  Future<void> _finishSession() => _cleanup ??= () async {
    final session = _session;
    _session = null;
    widget.onSessionChanged?.call(null);
    try {
      await _withAuth(
        (auth) => session == null ? auth.clearSession() : auth.logout(session),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('e-campus 세션 정리 중 오류가 발생했습니다. 다음 가져오기는 다시 로그인합니다.'),
          ),
        );
      }
    }
  }();

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

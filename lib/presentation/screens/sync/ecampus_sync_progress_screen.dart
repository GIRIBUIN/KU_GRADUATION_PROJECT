import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    this.loginBuilder,
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
  final Widget Function(
    BuildContext context,
    ValueChanged<EcampusSession> onLoggedIn,
  )?
  loginBuilder;
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
  Completer<EcampusSession?>? _inlineLogin;
  ValueChanged<EcampusSession>? _inlineLoginComplete;
  var _isFetching = false;
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
    _completeInlineLogin(null);
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
      child: _inlineLogin != null
          ? (widget.loginBuilder?.call(context, _inlineLoginComplete!) ??
                EcampusLoginWebViewScreen(onLoggedIn: _inlineLoginComplete))
          : Scaffold(
              appBar: AppBar(title: const Text('eCampus 가져오기')),
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_errorMessage == null) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            _isFetching ? '일정을 가져오는 중입니다.' : '로그인을 준비하고 있습니다.',
                          ),
                        ] else ...[
                          Icon(
                            Icons.error_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          const Text('eCampus 가져오기에 실패했습니다.'),
                          const SizedBox(height: 8),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _isSyncing ? null : _startSync,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('다시 시도'),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _cancelAndClose,
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<EcampusSession?> _openInlineLogin() async {
    final pending = Completer<EcampusSession?>();
    var delivered = false;
    setState(() {
      _inlineLogin = pending;
      _inlineLoginComplete = (session) {
        if (delivered) return;
        delivered = true;
        if (!pending.isCompleted) {
          pending.complete(session);
        } else {
          // Login can finish after cancellation or disposal. End that session
          // without resuming the import or accepting a second completion.
          _session = session;
          _cleanup = null;
          unawaited(_finishSession());
        }
      };
    });
    try {
      return await pending.future;
    } finally {
      if (mounted) {
        setState(() {
          _inlineLogin = null;
          _inlineLoginComplete = null;
        });
      }
    }
  }

  void _completeInlineLogin(EcampusSession? session) {
    final pending = _inlineLogin;
    if (pending != null && !pending.isCompleted) pending.complete(session);
  }

  Future<void> _startSync() async {
    if (_isSyncing || _cancelRequested) {
      return;
    }

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
      _isFetching = false;
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
          : await _openInlineLogin();

      _session = session;
      if (!mounted || _cancelRequested) {
        // A login result delivered after disposal still needs cleanup.
        if (session != null) _cleanup = null;
        return;
      }

      if (session == null) {
        shouldClose = true;
        return;
      }

      widget.onSessionChanged?.call(session);

      setState(() {
        _isFetching = true;
      });

      final result = await _flowService.preview(session: session);

      if (!mounted || _cancelRequested) {
        return;
      }

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
    _completeInlineLogin(null);
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
}

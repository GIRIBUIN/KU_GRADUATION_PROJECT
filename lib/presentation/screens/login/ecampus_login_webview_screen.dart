import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../data/services/ecampus_auth_service.dart';
import '../../../data/services/ecampus_login_detector.dart';

class EcampusLoginWebViewScreen extends StatefulWidget {
  const EcampusLoginWebViewScreen({
    super.key,
    this.initialUrl = 'https://ecampus.konkuk.ac.kr/ilos/main/main_form.acl',
    this.loginDetector = const EcampusLoginDetector(),
  });

  final String initialUrl;
  final EcampusLoginDetector loginDetector;

  @override
  State<EcampusLoginWebViewScreen> createState() =>
      _EcampusLoginWebViewScreenState();
}

class _EcampusLoginWebViewScreenState extends State<EcampusLoginWebViewScreen> {
  static const _cookieBaseUrls = [
    // e-campus can move between desktop/mobile and http/https during login.
    'https://ecampus.konkuk.ac.kr',
    'https://ecampus.konkuk.ac.kr/ilos/main/main_form.acl',
    'https://ecampus.konkuk.ac.kr/ilos/m/main/main_form.acl',
    'http://ecampus.konkuk.ac.kr',
    'http://ecampus.konkuk.ac.kr/ilos/main/main_form.acl',
    'http://ecampus.konkuk.ac.kr/ilos/m/main/main_form.acl',
  ];

  InAppWebViewController? _controller;
  var _isLoading = true;
  var _isCompletingLogin = false;
  String? _currentUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('e-campus 로그인'),
        actions: [
          IconButton(
            tooltip: '로그인 완료 확인',
            onPressed: _controller == null
                ? null
                : () => _tryCompleteLogin(_controller!, showFailure: true),
            icon: const Icon(Icons.check_rounded),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              if (!mounted) {
                return;
              }
              setState(() {
                _isLoading = true;
                _currentUrl = url?.toString();
              });
            },
            onLoadStop: (controller, url) async {
              if (!mounted) {
                return;
              }
              setState(() {
                _isLoading = false;
                _currentUrl = url?.toString();
              });
              await _tryCompleteLogin(controller);
            },
          ),
          if (_isLoading || _isCompletingLogin)
            const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }

  Future<bool> _tryCompleteLogin(
    InAppWebViewController controller, {
    bool showFailure = false,
  }) async {
    if (_isCompletingLogin) {
      return false;
    }

    _isCompletingLogin = true;
    try {
      for (var attempt = 0; attempt < 3; attempt += 1) {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }

        final html = await controller.evaluateJavascript(
          source: 'document.documentElement.outerHTML;',
        );
        final cookieMap = await _readEcampusCookies();

        final result = widget.loginDetector.detect(
          html: html?.toString() ?? '',
          cookies: cookieMap,
        );

        if (!mounted) {
          return false;
        }
        if (result.isLoggedIn) {
          Navigator.of(context).pop(
            EcampusSession(
              cookies: cookieMap,
              createdAt: DateTime.now(),
              lastUrl: _currentUrl,
            ),
          );
          return true;
        }
      }

      if (mounted && showFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '로그인 성공 신호를 찾지 못했습니다. '
              'e-campus 화면에 이름 또는 로그아웃이 보이면 다시 눌러주세요. '
              '현재 URL: ${_currentUrl ?? '-'}',
            ),
          ),
        );
      }
      return false;
    } finally {
      _isCompletingLogin = false;
    }
  }

  Future<Map<String, String>> _readEcampusCookies() async {
    final cookieMap = <String, String>{};
    final manager = CookieManager.instance();
    final urls = {..._cookieBaseUrls, ?_currentUrl};

    for (final baseUrl in urls) {
      final cookies = await manager.getCookies(url: WebUri(baseUrl));
      for (final cookie in cookies) {
        final value = cookie.value ?? '';
        if (value.trim().isNotEmpty) {
          cookieMap[cookie.name] = value;
        }
      }
    }

    return cookieMap;
  }
}

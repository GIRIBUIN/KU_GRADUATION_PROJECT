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
  static const _cookieBaseUrl = 'https://ecampus.konkuk.ac.kr';

  InAppWebViewController? _controller;
  var _isLoading = true;
  var _isCompletingLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('e-campus 로그인'),
        actions: [
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
              });
            },
            onLoadStop: (controller, url) async {
              if (!mounted) {
                return;
              }
              setState(() {
                _isLoading = false;
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

  Future<void> _tryCompleteLogin(InAppWebViewController controller) async {
    if (_isCompletingLogin) {
      return;
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
        final cookies = await CookieManager.instance().getCookies(
          url: WebUri(_cookieBaseUrl),
        );
        final cookieMap = <String, String>{
          for (final cookie in cookies)
            if ((cookie.value ?? '').trim().isNotEmpty)
              cookie.name: cookie.value ?? '',
        };

        final result = widget.loginDetector.detect(
          html: html?.toString() ?? '',
          cookies: cookieMap,
        );

        if (!mounted) {
          return;
        }
        if (result.isLoggedIn) {
          Navigator.of(context).pop(
            EcampusSession(cookies: cookieMap, createdAt: DateTime.now()),
          );
          return;
        }
      }
    } finally {
      _isCompletingLogin = false;
    }
  }
}

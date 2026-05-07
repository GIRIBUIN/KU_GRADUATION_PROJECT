import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../data/services/ecampus_auth_service.dart';

class InAppWebViewEcampusCookieStore implements EcampusCookieStore {
  const InAppWebViewEcampusCookieStore({
    CookieManager? cookieManager,
    List<String> cookieUrls = _defaultCookieUrls,
  }) : _cookieManager = cookieManager,
       _cookieUrls = cookieUrls;

  static const _defaultCookieUrls = [
    'https://ecampus.konkuk.ac.kr',
    'https://ecampus.konkuk.ac.kr/ilos/main/main_form.acl',
    'https://ecampus.konkuk.ac.kr/ilos/m/main/main_form.acl',
    'http://ecampus.konkuk.ac.kr',
    'http://ecampus.konkuk.ac.kr/ilos/main/main_form.acl',
    'http://ecampus.konkuk.ac.kr/ilos/m/main/main_form.acl',
  ];

  final CookieManager? _cookieManager;
  final List<String> _cookieUrls;

  @override
  Future<void> clearEcampusCookies() async {
    final manager = _cookieManager ?? CookieManager.instance();

    for (final url in _cookieUrls) {
      await manager.deleteCookies(url: WebUri(url));
    }
  }
}

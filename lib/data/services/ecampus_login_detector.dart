import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

import '../models/ecampus_auth_models.dart';

class EcampusLoginDetector {
  const EcampusLoginDetector();

  EcampusLoginDetectionResult detect({
    required String html,
    required Map<String, String> cookies,
  }) {
    final document = html_parser.parse(html);

    return EcampusLoginDetectionResult(
      hasUser: _hasUserSignal(document),
      hasLogoutButton: _hasLogoutButtonSignal(document),
      hasLogoutLink: _hasLogoutLinkSignal(document),
      hasTodoList: _hasTodoListSignal(document),
      hasSessionCookie: _hasSessionCookie(cookies),
    );
  }

  bool _hasUserSignal(html_dom.Document document) {
    return document.querySelector('#user') != null ||
        document.querySelector('#user_photo') != null ||
        document.querySelector('a[href*="myinfo"]') != null;
  }

  bool _hasLogoutButtonSignal(html_dom.Document document) {
    return document.querySelector('.header_logout') != null ||
        document.querySelector('.header_exit') != null;
  }

  bool _hasLogoutLinkSignal(html_dom.Document document) {
    return document.querySelector('a[href="/ilos/lo/logout.acl"]') != null ||
        document.querySelector('a[href*="logout.acl"]') != null;
  }

  bool _hasTodoListSignal(html_dom.Document document) {
    return document.querySelector('#todoList_cnt') != null ||
        document.querySelector('[title="Todo List"]') != null;
  }

  bool _hasSessionCookie(Map<String, String> cookies) {
    final sessionId = cookies['JSESSIONID'];
    return sessionId != null && sessionId.trim().isNotEmpty;
  }
}

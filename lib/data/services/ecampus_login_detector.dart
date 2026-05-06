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
      hasUser:
          document.querySelector('#user') != null ||
          document.querySelector('#user_photo') != null ||
          document.querySelector('a[href*="myinfo"]') != null,
      hasLogoutButton:
          document.querySelector('.header_logout') != null ||
          document.querySelector('.header_exit') != null,
      hasLogoutLink:
          document.querySelector('a[href="/ilos/lo/logout.acl"]') != null ||
          document.querySelector('a[href*="logout.acl"]') != null,
      hasTodoList:
          document.querySelector('#todoList_cnt') != null ||
          document.querySelector('[title="Todo List"]') != null,
      hasSessionCookie: _hasSessionCookie(cookies),
    );
  }

  bool _hasSessionCookie(Map<String, String> cookies) {
    final sessionId = cookies['JSESSIONID'];
    return sessionId != null && sessionId.trim().isNotEmpty;
  }
}

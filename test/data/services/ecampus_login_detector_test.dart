import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/services/ecampus_login_detector.dart';

void main() {
  const detector = EcampusLoginDetector();

  group('EcampusLoginDetector', () {
    test('does not classify login page as logged in even with JSESSIONID', () {
      final result = detector.detect(
        html: _beforeLoginHtml,
        cookies: const {'JSESSIONID': 'session-id'},
      );

      expect(result.hasSessionCookie, isTrue);
      expect(result.hasUser, isFalse);
      expect(result.hasLogoutButton, isFalse);
      expect(result.hasLogoutLink, isFalse);
      expect(result.isLoggedIn, isFalse);
    });

    test('classifies logged-in page with JSESSIONID as logged in', () {
      final result = detector.detect(
        html: _afterLoginHtml,
        cookies: const {'JSESSIONID': 'session-id'},
      );

      expect(result.hasUser, isTrue);
      expect(result.hasLogoutButton, isTrue);
      expect(result.hasLogoutLink, isTrue);
      expect(result.hasTodoList, isTrue);
      expect(result.hasSessionCookie, isTrue);
      expect(result.isLoggedIn, isTrue);
    });

    test('does not classify logged-in DOM without JSESSIONID as logged in', () {
      final result = detector.detect(
        html: _afterLoginHtml,
        cookies: const {'SCOUTER': 'scouter-id'},
      );

      expect(result.hasUser, isTrue);
      expect(result.hasLogoutButton, isTrue);
      expect(result.hasLogoutLink, isTrue);
      expect(result.hasSessionCookie, isFalse);
      expect(result.isLoggedIn, isFalse);
    });

    test('treats todo list as a supporting signal, not a required signal', () {
      final result = detector.detect(
        html: _afterLoginHtmlWithoutTodo,
        cookies: const {'JSESSIONID': 'session-id'},
      );

      expect(result.hasUser, isTrue);
      expect(result.hasLogoutButton, isTrue);
      expect(result.hasLogoutLink, isTrue);
      expect(result.hasTodoList, isFalse);
      expect(result.isLoggedIn, isTrue);
    });
  });
}

const _beforeLoginHtml = '''
  <div class="utillmenu">
    <ul>
      <a href="/ilos/main/member/login_form.acl">
        <li class="header_login login-btn-color">
          <div class="header_login_img"></div>
          <div>로그인</div>
        </li>
      </a>
    </ul>
  </div>
''';

const _afterLoginHtml = '''
  <div class="utillmenu">
    <div class="login">
      <fieldset class="welcome-message">
        <legend>로그인</legend>
        <strong class="site-font-color" id="user">USER_NAME</strong>
        <div class="message_content">
          <div class="message_item" title="Todo List">
            <div id="todoList_cnt" class="new_cnt site-background-color"></div>
          </div>
        </div>
        <a href="/ilos/lo/logout.acl">
          <div class="header_logout">로그아웃</div>
        </a>
      </fieldset>
    </div>
  </div>
''';

const _afterLoginHtmlWithoutTodo = '''
  <div class="utillmenu">
    <div class="login">
      <fieldset class="welcome-message">
        <strong class="site-font-color" id="user">USER_NAME</strong>
        <a href="/ilos/lo/logout.acl">
          <div class="header_logout">로그아웃</div>
        </a>
      </fieldset>
    </div>
  </div>
''';

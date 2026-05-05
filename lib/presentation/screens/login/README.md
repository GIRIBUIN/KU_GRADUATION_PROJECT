# login

WebView 기반 eCampus 로그인 화면.
크리덴셜을 앱에서 직접 수집하지 않고 WebView로 처리함.

## 현재 파일

- `ecampus_login_webview_screen.dart`: e-campus 로그인 페이지를 WebView로 표시하고 로그인 성공 시 `EcampusSession` 반환

## 로그인 성공 기준

- URL 변화는 사용하지 않는다.
- WebView DOM에서 `#user`, `.header_logout`, `/ilos/lo/logout.acl` 링크를 확인한다.
- WebView 쿠키에서 `JSESSIONID`가 존재하는지 확인한다.
- 성공 시 `Navigator.pop(context, EcampusSession)`으로 세션을 반환한다.

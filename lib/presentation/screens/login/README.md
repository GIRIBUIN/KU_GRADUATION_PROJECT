# login

WebView 기반 eCampus 로그인 화면.
크리덴셜을 앱에서 직접 수집하지 않고 WebView로 처리함.

이 화면은 Android WebView 기준으로 검증한다.
Chrome web 실행은 쿠키, 리다이렉트, WebView API 동작이 달라 수동 검증 대상에서 제외한다.

## 현재 파일

- `ecampus_login_webview_screen.dart`: e-campus 로그인 페이지를 WebView로 표시하고 로그인 성공 시 `EcampusSession` 반환

## 로그인 성공 기준

- URL 변화는 사용하지 않는다.
- WebView DOM에서 PC/모바일 로그인 완료 신호를 확인한다.
  - PC: `#user`, `.header_logout`, `logout.acl`
  - 모바일: `#user_photo`, `.header_exit`, `logout.acl`
- `todoList` 관련 요소는 보조 신호로만 사용한다.
- WebView 쿠키에서 `JSESSIONID`가 존재하는지 확인한다.
- 성공 시 `Navigator.pop(context, EcampusSession)`으로 세션을 반환한다.

## 세션 쿠키 회수

- e-campus는 로그인 중 `http`/`https`, PC/모바일 경로를 오갈 수 있다.
- 쿠키는 대표 URL들과 현재 WebView URL 기준으로 모두 조회한다.
- 계정 정보와 쿠키 값은 로그에 남기지 않는다.

# eCampus WebView 로그인

현재 기준: 2026-11-15.

ecampus_login_webview_screen.dart가 DOM 로그인 신호와 쿠키로 EcampusSession을 반환한다. 가져오기 화면이 inline WebView로 구성하는 경우에도 같은 컴포넌트를 사용한다.

매번 가져오기 시작 시 이전 쿠키를 정리하고 사용자 로그인을 받는다. 종료/실패/취소 후 세션 참조·eCampus 도메인 쿠키를 정리한다. 계정 입력/비밀번호를 앱 설정·DB에 저장하지 않는다. 검증 기준은 Android WebView이며 웹 브라우저에서 같은 인증 동작을 보장하지 않는다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../../../../docs/README.md)를 본다.

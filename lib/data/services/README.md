# services

외부 시스템 연동, HTML 요청/파싱, 동기화 같은 작업의 인터페이스를 둔다.
Repository가 앱 내부 저장소를 다룬다면, service는 e-campus나 알림 시스템 같은 외부 작업을 담당한다.

## 현재 파일

- `ecampus_auth_service.dart`: e-campus 로그인, 로그아웃, 세션 처리
- `http_ecampus_auth_service.dart`: e-campus logout 요청과 세션 clear 처리
- `ecampus_login_detector.dart`: WebView DOM과 쿠키를 기준으로 로그인 성공 여부 판정
- `ecampus_todo_client.dart`: 세션을 사용해 todo HTML을 가져오는 저수준 계약
- `http_ecampus_todo_client.dart`: WebView 세션 쿠키로 e-campus todo HTML을 요청하는 HTTP 구현
- `ecampus_todo_service.dart`: todo HTML 요청 및 HTML 파싱
- `default_ecampus_todo_service.dart`: todo client와 parser를 조합하는 기본 구현
- `ecampus_todo_parser.dart`: todo HTML을 `ParsedEcampusTask`와 파싱 실패 목록으로 변환
- `ecampus_sync_service.dart`: 동기화 미리보기, 선택 항목 가져오기, 제외 처리
- `default_ecampus_sync_service.dart`: todo 요청, 파싱, 분류를 묶어 `SyncResult`를 생성
- `ecampus_sync_classifier.dart`: 파싱 결과와 기존 Task를 비교해 동기화 결과 분류

## 데이터 흐름

```text
로그인
→ WebView 세션 생성
→ todo HTML 요청
→ HTML 파싱
→ ParsedEcampusTask 생성
→ SyncResult 분류
→ 사용자가 선택한 항목 반영
```

## 구현 원칙

- 이 폴더에는 인터페이스를 먼저 둔다.
- WebView 로그인은 사용자가 직접 인증한 뒤 세션 쿠키만 앱으로 전달한다.
- 로그인 수동 검증은 Android WebView 기준이며 Chrome web 실행은 기준으로 삼지 않는다.
- todo HTTP 요청은 WebView 세션 쿠키를 `Cookie` 헤더로 전달한다.
- logout은 세션 쿠키로 e-campus logout endpoint를 호출한 뒤 WebView 쿠키를 삭제한다.
- 세션이 만료되어 로그인 화면 HTML이 반환되면 세션 만료 오류로 처리한다.
- 계정 정보, 세션, 쿠키는 로그에 남기지 않는다.

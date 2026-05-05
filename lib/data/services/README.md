# services

외부 시스템 연동, HTML 요청/파싱, 동기화 같은 작업의 인터페이스를 둔다.
Repository가 앱 내부 저장소를 다룬다면, service는 e-campus나 알림 시스템 같은 외부 작업을 담당한다.

## 현재 파일

- `ecampus_auth_service.dart`: e-campus 로그인, 로그아웃, 세션 처리
- `ecampus_todo_service.dart`: todo HTML 요청 및 HTML 파싱
- `ecampus_todo_parser.dart`: todo HTML을 `ParsedEcampusTask`와 파싱 실패 목록으로 변환
- `ecampus_sync_service.dart`: 동기화 미리보기, 선택 항목 가져오기, 제외 처리
- `ecampus_sync_classifier.dart`: 파싱 결과와 기존 Task를 비교해 동기화 결과 분류

## 데이터 흐름

```text
로그인
→ 세션 생성
→ todo HTML 요청
→ HTML 파싱
→ ParsedEcampusTask 생성
→ SyncResult 분류
→ 사용자가 선택한 항목 반영
```

## 구현 원칙

- 이 폴더에는 인터페이스를 먼저 둔다.
- 실제 네트워크, WebView, parser 구현은 후속 커밋에서 추가한다.
- 계정 정보, 세션, 쿠키는 로그에 남기지 않는다.

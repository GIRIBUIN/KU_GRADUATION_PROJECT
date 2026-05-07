# local

Drift 기반 로컬 SQLite DB 스키마를 둔다.

## 현재 파일

- `app_database.dart`: Task, Tag, Folder, Notification, 설정 저장을 위한 Drift 스키마

## 스키마 원칙

- 앱 내부 id는 문자열을 사용한다.
- enum 값은 문자열로 저장한다.
- 날짜/시간 값은 Drift `DateTimeColumn`으로 저장한다.
- e-campus source metadata는 `tasks` 테이블 안에 둔다.
- 제외 항목은 별도 테이블 없이 `tasks.status = excluded`와 `ecampus_source_key`로 표현한다.
- Repository 구현은 후속 커밋에서 추가한다.

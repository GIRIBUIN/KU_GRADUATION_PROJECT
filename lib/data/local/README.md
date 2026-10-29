# local

Drift 기반 로컬 SQLite DB 스키마를 둔다.

## 현재 파일

- `app_database.dart`: DB 버전 6의 일정·원본·분류·알림·이관 기록 스키마
- `schema_v6_migration.dart`: 기존 DB 이관과 예외 데이터 기록
- [DB v6 관계도](../../../docs/diagrams/db-v6.md): 현재 테이블·외래키와 변환용 Mermaid 원본

## 스키마 원칙

- 앱 내부 id는 문자열을 사용한다.
- 새 ID는 UUID, 기존 ID는 이관 시 보존한다.
- 날짜/시간은 Drift `DateTimeColumn`의 Unix 초를 사용한다. Kotlin의 밀리초 저장 형식을 복사하지 않는다.
- `tasks`는 사용자 일정이고 eCampus 원본은 `ecampus_courses`·`ecampus_items`에 분리한다. 제외 항목은 `ecampus_items.import_state`에만 저장한다.
- Task의 완료·삭제 상태는 시각에서 계산한다. 단일 폴더와 전역 태그를 사용하고 외래키를 활성화한다.
- `task_reminders`의 분 단위 알림 규칙과 `local_notification_schedules`의 기기별 예약 결과를 구분한다.
- 이관된 DB에는 원본 행을 보존한 `legacy_v5_*` 테이블과 모순 데이터를 설명하는 `migration_issues`가 남는다.
- UI의 기존 DTO는 Repository·Mapper에서 변환한다. 새 스키마와 측정 결과는 [설계·적용 기록](../../../docs/specifications/DB%20재설계%20비교와%20적용안.md)을 참고한다.

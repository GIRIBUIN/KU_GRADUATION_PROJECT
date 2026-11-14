# Drift DB v7

현재 기준: 2026-11-15.

app_database.dart가 14개 활성 테이블·schemaVersion 7을 정의한다. schema_v6_migration.dart와 schema_v7_migration.dart가 과거 데이터 이관·원본 보존을 처리한다.

Task는 task_lists의 목록 하나에 필수 소속된다. 상위 폴더는 folder_groups, 원본은 ecampus_items/courses, 태그는 독립 관계다. status/origin은 DTO 변환이고 tasks의 물리 컬럼이 아니다. legacy_*는 이관 DB의 보관 테이블이다. 현재 UI의 목록 보관/복원 메뉴는 제거됐다. 일반 생성은 UUID, 위젯 draft는 기존 시각 기반 ID를 사용하며 이관 ID는 유지한다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../../../docs/README.md)를 본다.

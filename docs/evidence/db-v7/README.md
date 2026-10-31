# 목록·상위 폴더 적용 검증 — 2026-10-30

범위: 기존 폴더를 목록으로 보존하고 상위 폴더·필수 목록 소속·수집함·강의별 기본 배치를 추가했다. 기기 간 동기화는 추가하지 않았다.
구조와 코드 호환 경계는 [DB v7 관계도](../../diagrams/db-v7.md)에 정리했다.

주요 코드:

- [DB·스키마](../../../lib/data/local/app_database.dart), [v6→v7 이관](../../../lib/data/local/schema_v7_migration.dart), [v5→현재 이관](../../../lib/data/local/schema_v6_migration.dart)
- [목록·폴더 관리](../../../lib/data/repositories/drift_folder_repository.dart), [필수 소속·과목 배치](../../../lib/data/repositories/drift_task_repository.dart)
- [생성·상세 목록 선택](../../../lib/presentation/widgets/task_metadata_picker.dart), [관리 화면](../../../lib/presentation/screens/main/main_shell_screen.dart), [가져오기 선택](../../../lib/presentation/screens/sync/ecampus_sync_preview_screen.dart)

신규 검증:

- [DB v7 테스트 9건](../../../test/data/local/database_v7_lists_test.dart): Inbox 필수 소속, 상위 폴더 ID 직접 할당 거부, 수집함 보호, 폴더 삭제 후 목록 유지, 목록 보관·완료·휴지통 복원 소속 보존, 과목 식별값별 배치·수동 이동 보존, 보관된 과목 목록 처리, v6 이관의 원본·하위 외래키·완료 시각 보존, 이관 실패 rollback.
- [360px 화면 테스트 3건](../../../test/presentation/screens/list_groups_test.dart): 기본 수집함 저장, School 폴더 아래 과목 목록 생성, 완료 Task가 있는 목록의 보관·복원.
- 기존 가져오기 화면 테스트에 NEW의 명시적 수집함 선택 1건 추가.
- [v6 SQL fixture](../../../test/fixtures/database/schema_v6.sql)는 이 변경 전 실제 v6 메모리 DB의 sqlite_master에서 추출했다. 개인정보가 없는 빈 스키마다.

최종 검증 원본:

전체 데이터·화면 테스트 **186건 통과**(이전 173건 + 신규 13건). 분석 오류·경고 0건, 기존 onReorder deprecation info 1건. Android debug APK 빌드 성공.

- [전체 데이터·화면 테스트](lists-tests-20261030.jsonl)
- [정적 분석](lists-analyze-20261030.txt)
- [Android debug APK 빌드](lists-build-20261030.txt)
- [검증 요약·소스/APK 해시](lists-summary-20261030.json)

이전 `db/`·`ecampus/` 기록은 해당 버전의 시점 기록으로 유지한다. 새 APK를 실제 기기에 설치하거나 실제 사용자 DB 이관·실제 eCampus 계정으로 이 변경을 확인한 것은 아니다.

전체 Task 조회 탭은 ‘전체’, 실제 저장 위치는 ‘목록’으로 구분했다. 앱 코드·테스트·기록은 아직 커밋하지 않았다.

직접 확인: 기존 데이터가 있는 기기에 새 APK 설치 → 기존 목록·완료·휴지통 소속 확인 → 수집함 기본 생성 → School 폴더·과목 목록 생성·이동 → eCampus NEW 자동 배치/명시적 목록 선택 → Task를 다른 목록으로 이동한 후 재가져오기 → 목록 보관·복원.

## 목록·폴더 조작 보완 — 2026-10-30

앞선 186건은 목록 구조 적용 시점의 결과이며 아래는 관리 화면 조작을 보완한 뒤의 별도 검증이다. DB v7 스키마는 변경하지 않았다.

- 수집함은 다른 목록과 같은 네모 아이콘을 사용하며 색상을 편집할 수 있다. 이름·소속·보관·숨김·드래그 변경은 막는다.
- 폴더 탭은 목록 펼침·접기로 변경했다. 할 일 화면은 목록을 눌렀을 때 연다.
- 목록을 길게 눌러 폴더에 놓으면 소속 폴더를 저장하고 펼친다. ‘폴더 밖’에 놓으면 루트로 이동한다. 다른 목록에 놓으면 해당 폴더로 이동하며 그 목록 앞에 배치한다. 이동은 하나의 DB transaction으로 처리하고 Task 소속과 이력은 건드리지 않는다.
- 관리·추가·선택·할 일 표시의 목록 아이콘을 색상 네모로 통일했다. 폴더와 태그는 기존 모양을 유지한다.
- 변경 파일: `drift_folder_repository.dart`, `folder_repository.dart`, `main_shell_screen.dart`, `task_metadata_picker.dart`와 아래 테스트 2개다.
- 회귀 4건 추가: [폴더 펼침/목록 열기·실제 길게 누르기 드래그·수집함 색상과 고정 제약](../../../test/presentation/screens/list_groups_test.dart), [목록 이동·순서·잘못된 이동 rollback·완료/휴지통 연결 보존](../../../test/data/local/database_v7_lists_test.dart).

전체 데이터·화면 테스트 **190건 통과**. 정적 분석 오류·경고 0건, 기존 onReorder deprecation info 1건. Android debug APK 빌드 성공. 실제 기기 설치·드래그 조작은 미수행이다.

- [테스트 원본](interaction-tests-20261030.jsonl)
- [정적 분석](interaction-analyze-20261030.txt)
- [APK 빌드](interaction-build-20261030.txt)
- [검증 요약·소스/APK 해시](interaction-summary-20261030.json)

직접 확인: 새 APK 설치 → 관리에서 목록을 길게 눌러 접힌 폴더로 이동 → 폴더 접기·펼치기 → 목록을 눌러 할 일 확인 → ‘폴더 밖’으로 드래그 → 수집함 색상 변경 및 이름/이동/보관 불가 확인. 이번 변경도 아직 커밋하지 않았다.

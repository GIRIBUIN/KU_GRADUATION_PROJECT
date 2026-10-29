# DB 재설계 비교와 적용안

기준일: 2026-10-29. Kotlin 설계를 기준으로 Flutter의 실제 사용 기능을 대조했다.
2026-10-30: 이 기준으로 Flutter DB 버전 6, 버전 5 이관, Repository와 관련 화면·위젯 연결을 코드에 적용했다. 실제 사용자 기기에 설치해서 DB를 이관한 것은 아니다. 아래 비교표와 R1~R5는 변경 전 기록이다.
대상은 Android·iOS 우선, 이후 웹이다. Kotlin 앱을 먼저 완성하는 작업은 하지 않는다.
2026-10-30 사용자 확인: 우선 WebView를 고려해 DB 개선을 진행한다. 개발 단계의 검증·포트폴리오 완성을 우선하고 OCR은 후속 과제로 보존하며 현재 DB 구현의 선행 조건으로 삼지 않는다. [OCR 검토 기록](OCR%20가져오기와%20DB%20변경.md)은 후속 설계에 사용한다.
기기 간 동기화는 기존 개발 목표로 유지한다. eCampus 입력 방식과 별도 기능이다.

## 1. 비교 결과

| 항목 | Flutter 원본 | Kotlin 개발본 | 적용 방향 |
| --- | --- | --- | --- |
| 사용자 일정 / eCampus 원본 | Tasks에 함께 저장 | Task·Course·Item 분리 | Kotlin 구조 채택 |
| 원본 상태 | Task.status에 제외까지 혼재 | importState / sourceState 분리 | 원본 식별과 가져오기 선택을 일정 상태와 분리. 누락은 사용자 검토 |
| 동기화 | preview에서도 DB 변경, 항목별 저장 | prepare / review / transaction commit | 읽기 전용 미리보기와 선택 항목의 원자적 저장 적용. 누락 자동 완료 제거. OCR은 후속 |
| 변경 반영 | 제목·마감일·메모 등을 함께 갱신 | 필드별 적용 / 현재 값 유지 | 필드별 선택, 사용자 메모 보존 |
| 기본 ID | 문자열, 시각·원본키 기반 생성 | 자동 증가 Long | 문자열 ID 유지, 신규는 UUID. 기존 ID 재발급 금지 |
| 우선순위 / 일정 사용자 정렬 | 있음 | Task에 없음 | 최종 Task에 유지 |
| 하위 일정 | 별도 테이블, 생성 시각 정렬 | 별도 테이블, 명시적 position | Kotlin position 채택, Task.parentTaskId 중복 제거 |
| 폴더 | 계층·색상·태그 배치·정렬 | 단일 단계, Task.folderId | 단일 단계로 단순화. 일정의 소속만 표현 |
| 태그 범위 | 설정 JSON에 태그의 폴더 배치 저장 | 전역 Tag와 TaskTag | 전역 태그 채택. 폴더와 독립적으로 일정에 연결 |
| 일정-폴더 개수 | 모델은 복수, 저장은 첫 항목만 | 단일 폴더 | Task.folderId 하나로 명시. 기존 복수 관계는 이관 전 보고 |
| 삭제·복구 | 휴지통 있음 | Task 물리 삭제, 원본 제외 | 휴지통·삭제 기록 유지. 제외와 삭제 구분 |
| 알림 | 별도 설정 + 로컬 예약 | offset 필드, 재예약 대상 ID 반환 | 알림 규칙과 기기별 예약 상태 분리 |
| 앱 설정 | 표시·관계 정보가 JSON에 함께 저장 | 대응 구현 없음 | 실제 관계는 테이블, 기기 표시 설정은 로컬 설정 |
| 기기 간 동기화 | 없음 | 없음 | 안정 ID·삭제 기록 준비. 서버·충돌 규칙은 후속 설계 |

사용자 확인 기준은 폴더 한 단계와 전역 태그다. 하위 폴더와 태그의 폴더 소속은 두지 않는다.
일정은 폴더 하나에 속하거나 미분류이며, 태그는 폴더와 독립적으로 여러 일정에 붙인다.
전체 목록의 A 태그 조회와 특정 폴더 안의 A 태그 조회를 모두 지원한다. 후자는 folderId 조건과 TaskTag의 tagId 조건을 함께 적용한다.
태그를 사용하거나 수정해도 일정의 폴더는 바뀌지 않는다. 태그는 특정 폴더로 이동하는 대상이 아니다.
Kotlin도 최종 완성본으로 간주하지 않는다. 누락된 기능을 보완하면서 데이터 처리 규칙을 가져온다.

## 2. 원본에서 재현한 문제

실제 사용자 데이터 대신 새 메모리 DB와 고정 입력을 사용했다.
재현 코드: [db_contract_audit.dart](../../test/benchmarks/db_contract_audit.dart).
원본 결과: [contract-audit JSON](../evidence/db/contract-audit-2026-10-29T14-39-52-139024Z.json).

| 번호 | 입력·절차 | 실제 관찰 | 최종 처리 규칙 |
| --- | --- | --- | --- |
| R1 | 폴더 A·B를 가진 Task 생성 | A만 저장됨 | 단일 folderId를 API·DB에서 동일하게 표현 |
| R2 | 일정 완료 후 active로 변경 | active인데 completedAt이 남음 | 완료 해제는 completedAt=null. 상태를 중복 저장하지 않음 |
| R3 | 사용자 메모가 있는 일정의 원본 변경 반영 | 메모가 과목명으로 바뀜 | 원본 갱신이 사용자 메모·태그·폴더를 덮어쓰지 않음 |
| R4 | TODO 요소 없는 예상 밖 HTML로 preview 호출 | 오류 0개·목록 0개로 처리되고 미래 일정이 완료됨 | preview는 일정 DB에 쓰지 않음. OCR에서 안 보인 항목은 기존 일정에 영향 없음 |
| R5 | 부모·자식 폴더 생성 후 부모 삭제 | 자식에 삭제된 부모 ID가 남음. FK pragma=0 | 연결마다 FK 활성화 확인. 최종안은 계층 제거, 폴더 삭제·참조 정리는 한 트랜잭션 |

R4는 TODO 서비스 경계에 HTML을 주입한 재현이다. 실제 HTTP·로그인 전체를 재현한 결과는 아니다.
R5는 NativeDatabase.memory 환경이다. 실기기 연결에서도 같은 설정인지는 아직 확인하지 않았다.
재현 스크립트 성공은 문제가 수정됐다는 뜻이 아니다. 관찰값은 JSON에 저장했다.

추가 코드 확인 사항:

- Flutter 동기화 항목들은 각각 저장되므로 여러 항목 반영 도중 오류가 나면 전체 작업의 원자성이 보장되지 않는다. Kotlin commit 구조를 채택한다.
- Flutter 메인 화면이 과목명·태그명으로 자동 폴더 배치를 복구하던 코드는 제거했다. 새 가져오기에서 태그·폴더를 자동 생성·강제 배치하지 않고 사용자 분류를 독립적으로 유지한다. 기존 분류는 이관 시 보존한다.
- 알림의 daysBeforeDue는 현재 분 단위다. 이름 추측으로 변환하지 않고 기존 notifyTime과 저장 형식에 따라 이관한다.
- Android 오늘 위젯은 DB를 직접 수정하고 주간 위젯은 pending 큐를 쓴다. 최종 DB의 완료 규칙·시각 단위·변경 추적 계약을 두 경로 모두에 적용해야 한다.
- Kotlin도 rawItemCount=0, items=0이면 구조 완전성 조건을 만족한다. 예상 밖 HTML을 정상 빈 목록과 구별하는 검사는 그대로 가져오지 않고 보완한다. Kotlin 측 런타임 재현은 아직 하지 않았다.

근거 위치:
[Flutter Task 저장소](../../lib/data/repositories/drift_task_repository.dart),
[동기화 흐름](../../lib/data/services/ecampus_sync_flow_service.dart),
[동기화 반영](../../lib/data/services/ecampus_sync_apply_service.dart),
[폴더 저장소](../../lib/data/repositories/drift_folder_repository.dart),
[설정 매퍼](../../lib/data/local/mappers/metadata_mappers.dart),
[메인 화면](../../lib/presentation/screens/main/main_shell_screen.dart),
[오늘 위젯 DB 수정](../../android/app/src/main/kotlin/com/example/ku_task_management/WidgetTaskCompleter.kt).

## 3. 최종 데이터 모델 기준안

이름은 논리 모델 기준이다. 실제 Drift 컬럼명과 버전 5→다음 버전의 변환 코드는 별도 변경으로 구현한다.

| 모델 | 주요 필드·역할 | 핵심 제약 |
| --- | --- | --- |
| Task | id, title, memo, dueAt, priority, folderId, sortOrder, completedAt, deletedAt, createdAt, updatedAt | active/completed/deleted 표시는 시각에서 계산. excluded 상태 없음 |
| SubTask | id, taskId, title, position, completedAt, deletedAt, createdAt, updatedAt | Task의 자식은 이 테이블만 사용 |
| Folder | id, name, color, icon, position, deletedAt, createdAt, updatedAt | 계층 없음. 삭제 시 일정의 소속만 해제. 태그는 영향 없음 |
| Tag | id, name, color, position, deletedAt, createdAt, updatedAt | 전역 태그. folderId 없음. 이름을 원본 식별자로 사용하지 않음 |
| TaskTag | taskId, tagId, updatedAt, deletedAt | 복합 고유키. 연결 해제도 나중에 기기 간 전달할 수 있도록 기록 |
| EcampusCourse | id, sourceScopeId, externalCourseKey?, name, tagId, lastObservedAt | 내부 UUID. OCR 과목명은 후보 정보이며 이름만으로 같은 과목이라고 강제하지 않음 |
| EcampusItem | id, sourceScopeId, courseId?, externalKey?, sourceTitle, sourceStartAt?, sourceEndAt?, taskId?, importState, firstObservedAt, lastObservedAt | 내부 UUID. externalKey는 레거시 입력 등에 존재할 때만 범위 내 고유. OCR 문자열 해시는 고유키가 아님 |
| ImportSession | id, provider, inputMethod, sourceScopeId, startedAt, endedAt, state, appliedCount | 이번 구현은 선택 반영 작업의 성공 기록. 전체 로그인 세션·조회 범위 기록은 아님. 원본 식별키로 반복 추가 방지 |
| TaskReminder | taskId, enabled, offsetMinutes, updatedAt | 일정당 최대 1개. offsetMinutes>=0. 비활성화해도 선택한 offset 보존 |
| LocalNotificationSchedule | taskId, platformNotificationId, scheduledAt, lastError | 기기 로컬 상태. 예약 ID 고유, 서버에 예약 결과를 공유하지 않음 |
| LocalSettings | 홈 구성·선택 상태·기기별 표시·권한 관련 설정 | 태그 소속·정렬 같은 도메인 관계는 넣지 않음 |
| DeletedEntity | entityType, entityId, deletedAt | 사용자가 일정을 영구 삭제할 때 삭제 ID를 먼저 기록. 서버 전달은 후속 |
| MigrationIssue | entityId, reason, legacyData | 모순 데이터의 이관 결과 기록. 원래 행은 legacy_v5_* 테이블에 별도 보존 |

ImportObservation과 화면별 OCR 근거 저장은 후속 OCR 구현 때 추가한다. 현재 스키마에 캡처·프레임·인식 신뢰도 관련 테이블을 먼저 만들지 않는다.
WebView 입력은 외부 식별키를 사용해 기존 항목을 대조한다. 앱 내부 UUID는 유지하며 실제 일정 처리를 WebView나 HTML 클래스에 직접 결합하지 않는다.

적용한 공통 규칙:

- 신규 공유 데이터 ID는 UUID 문자열, 기존 Flutter ID는 유지한다. 시각만으로 새 ID를 만들지 않는다.
- Task의 삭제가 완료 여부를 지우지 않는다. 휴지통 복원은 deletedAt만 지워 이전 완료 여부를 유지하는 안으로 한다. 기존 Flutter의 무조건 active 복원과 달라지는 정책이다.
- EcampusItem의 imported는 연결된 Task가 있어야 한다. ignored/unreviewed는 Task를 만들지 않는다. 가져온 일정이 휴지통에 가도 원본 연결을 유지해 재수집 중복을 막는다.
- WebView 입력에서는 외부 식별키로 비교하고 제목·마감일 변경을 검토한다. 누락 판단은 오류 없는 응답과 해당 조회 범위의 유효성을 확인한 뒤 수행하며, 누락이 곧 완료·삭제를 뜻하지 않는다.
- 수집·미리보기는 기존 Task를 변경하지 않는다. 사용자 선택 확정 후 트랜잭션으로 반영하고 취소·통신·파싱 실패는 기존 일정을 보존한다. 검토 중 수정된 기존 일정은 commit 직전 다시 확인한다.
- 후속 OCR 입력에서는 기존 항목 연결을 사용자 확인 후 확정하고 안 보인 항목을 누락으로 처리하지 않는다. 구체적인 관측·매칭 규칙은 OCR 검토 기록에 분리한다.
- 휴지통은 deletedAt으로 처리한다. 사용자가 영구 삭제하면 DeletedEntity를 기록한 뒤 원자적으로 상세 데이터·연결을 정리하고 원본은 ignored로 유지한다. 태그·폴더·연결의 논리 삭제는 각각 삭제 시각을 남긴다. 삭제 기록의 서버 전달·보존 기간은 후속이다.
- 관계·상태·알림 규칙 변경은 한 데이터 변경 서비스에서 트랜잭션으로 처리한다. OS 알림 예약과 위젯 갱신은 commit 이후 수행하고 실패 시 재시도할 수 있게 한다.
- 목록은 관계를 일괄 조회한다. 현재 100개/1,000개에서 SELECT 201회/2,001회인 기준 측정과 별도로 비교한다.
- 물리 시각 단위는 기존 Drift·Android 위젯과 같은 Unix 초를 유지했다. 이관은 Flutter v5 데이터만 대상으로 하며 Kotlin DB 파일을 복사하지 않는다. Kotlin의 Instant 밀리초 코드를 그대로 가져오지 않았다. 화면에서는 지역 시각으로 표시한다.
- 기존 UI의 Task·Folder·NotificationSetting DTO는 호환 경계로 남겼다. 실제 DB에는 origin/status/parentTaskId/태그-폴더 관계가 없고, excluded 항목은 원본 레코드를 UI DTO로 변환한다. daysBeforeDue도 호환 DTO 이름이며 실제 알림 테이블은 offsetMinutes다.

기기 간 동기화 전에 추가 확정할 항목:

- 현재 sourceScopeId는 단일 로컬 데이터셋을 뜻하는 legacy-local이다. 확인된 LMS 계정 ID가 아니며 다중 계정 분리는 아직 지원하지 않는다. 기기 간 동기화 전에 앱 사용자·기관·eCampus 계정 범위를 확정해야 한다. 인증정보·쿠키는 이 ID로 저장하지 않는다.
- 계정·서버·충돌 해결·삭제 보존 기간·변경 큐 형식은 아직 선택하지 않았다. updatedAt만으로 동시 수정 충돌이 해결된다고 간주하지 않는다.
- 로컬 알림 예약 상태와 eCampus 인증 세션은 기기 간 동기화 대상에서 제외한다. 공유할 원본의 사용자 선택·일정·분류 데이터와 구분한다.

## 4. 적용 순서와 증거

1. Kotlin 기반의 데이터 모델과 Flutter 필수 기능을 반영해 Drift 스키마·제약·Repository를 구현한다. WebView 수동 가져오기의 현재 실행 가능 범위도 구분해 확인한다.
2. 신규 DB 계약 테스트에서 단일 폴더, 전역 태그, 완료 해제, 사용자 메모 보존, FK, 알림 단위, 원본 식별키, 반복 반영을 확인한다. 실제 연동이 제한되면 익명화한 HTML fixture로 재현 가능한 데모를 구성하고 그 범위를 명시한다.
3. Flutter v5의 ID·태그·일정의 폴더 연결·정렬·알림·제외 원본을 새 구조로 이관한다. 기존 하위 폴더는 ID와 일정 연결을 유지한 독립 폴더로 펼치고 원래 경로를 이름에 표시한다(예: `학업 / 2학기`). 태그와 TaskTag는 유지하고, 옛 tagFolderIds는 이관 기록에 보존하되 새 도메인 관계로 만들지 않는다. 삭제하거나 같은 이름만 보고 합치지 않고 이관 대응표를 남긴다. course/item 키를 분해할 수 없는 행은 원본키와 데이터를 보존하고 보고한다. 과목명만 보고 합치지 않는다.
4. 복수 폴더 관계, 고아 참조, 중복 알림 등 모순 데이터는 이관 전에 건수·대상을 확인한다. 조용히 첫 값만 남기거나 삭제하지 않는다.
5. WebView 가져오기 수집/검토/commit과 기존 UI·위젯·알림을 연결한다. 목록 미리보기 취소 시 Task DB 동일성을 확인한다. 기존의 미리보기 중 누락 자동 완료는 제거한다.
6. 같은 입력으로 조회 시간·SQL 수를 재측정하고, 동일 시나리오의 전후 결과와 커밋을 짧게 기록한다. 모바일 실행 결과는 호스트 측정과 따로 남긴다.
7. 기기 간 동기화를 별도 변경으로 구현·검증한다. 현재 개발 범위의 시연·측정·수정 전후 기록을 포트폴리오로 정리하고 OCR은 이후 검토한다. 비배포를 근거로 학교의 허용 여부를 확정하지 않는다.

현재 적용 결과와 전후 측정은 [작업 기록 DB-005](../개선%20작업%20기록.md)에 있다. WebView의 실제 계정 로그인·실기기 DB 이관·iOS 실행·기기 간 동기화·OCR은 이번 검증에 포함하지 않았다. Kotlin의 별도 누락 검토 UI도 이번 DB 적용 범위에서 이식하지 않았다.

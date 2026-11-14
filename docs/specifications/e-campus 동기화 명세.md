# eCampus 가져오기 명세

현재 기준: 2026-11-15 / Flutter main. 파일명의 동기화는 eCampus 원본 비교·가져오기를 뜻하며 기기 간 동기화가 아니다.

## 조회·식별

[HTTP client](../../lib/data/services/http_ecampus_todo_client.dart)는 세션 Cookie로 체크리스트를 POST 조회한다.
[parser](../../lib/data/services/ecampus_todo_parser.dart)는 `div.todo_wrap`에서 제목·과목·마감·유형과 식별 인자를 추출한다.
`sourceKey = rawLectureId:rawItemId:rawType`. 식별 인자가 없으면 임의 fallback을 만들지 않고 오류 항목으로 분리한다.
DB에서는 기본 source scope와 external_key의 조합으로 원본을 식별한다.

## 분류

| 코드 분류 | 판단·사용자 선택 |
| --- | --- |
| newItem | 비교 대상에 같은 key 없음. 가져오기 / 신규 제외 |
| updateCandidate | 미완료 기존 원본의 제목·마감·과목·유형이 새 원본과 다름. 제목·마감 각각 선택 |
| alreadyImported | 같은 원본, 변경 없음 |
| completed / deleted / excluded | 기존 완료·휴지통·ignored 원본. 일반 변경 후보와 구분 |
| missing | 완전한 조회에서 기존 미완료 key가 사라짐. 기본 유지 / 완료 / 삭제 |
| error | 파싱·식별 실패 또는 누락 안전 조건 안내 |

변경 검사는 사용자 제목이 아니라 **이전 원본 snapshot**과 새 원본을 비교한다.
사용자가 제목을 직접 바꿨다는 사실만으로 원본 변경 후보가 되는 것은 아니다.

## 미리보기와 반영

[DefaultEcampusSyncFlowService.preview](../../lib/data/services/ecampus_sync_flow_service.dart)는 완료·삭제·제외까지 포함해 기존 eCampus 비교 대상을 읽는다.
preview는 DB를 쓰지 않는다. 결과는 현재 별도 EcampusSyncPreviewScreen에서 검토한다.

[DefaultEcampusSyncApplyService._commit](../../lib/data/services/ecampus_sync_apply_service.dart)의 현재 Drift 경로는 선택 batch를 atomic으로 저장한다.
실패 시 전체 rollback하며 완료/삭제된 항목은 일반 새 원본으로 덮어쓰지 않는다.
검토 이후 ID·상태·제목·마감·메모·우선순위·태그·목록 변경을 검사한다.
이 검사가 SubTask나 모든 원본 메타데이터까지 포함한 전체 DB 버전 잠금이라는 뜻은 아니다.

- NEW 가져오기: 새 Task·원본 연결. 명시한 목록 또는 강의별 기본 목록 사용. 기본 priority는 medium이며 과목명을 메모/태그로 강제 주입하지 않는다.
- NEW 제외: ignored 원본만 보관. 사용자 작업은 생성하지 않는다.
- CHANGED: applyTitle/applyDueDate에 따라 선택 필드만 원본 적용. 메모·우선순위·태그·목록·완료/삭제 시각 보존.
- CHANGED 현재 값 유지(exclude 경로 포함): 사용자 제목·마감 유지, 원본 snapshot 갱신. 신규 제외와 의미가 다르다.
- MISSING 유지: 작업·연결 유지. 완료는 기존 updateTaskStatus, 삭제는 markDeleted 경로 사용.

같은 NEW 선택을 재적용하면 기존 원본 연결을 찾아 중복 생성을 건너뛴다.
반영 성공 기록은 ImportSessions이며 실패/취소 전체 세션 로그를 현재 구현했다고 쓰지 않는다.

## MISSING 안전 조건

`parseResult.isComplete && !parseResult.hasFailures`일 때만 차집합 감지를 켠다.
classifier도 빈 key/중복을 방어하고 기존 active eCampus만 후보로 만든다.
정상 no_data 표시와 구조 미확인 빈 HTML을 구분하며, 잘린 HTML·실제 추가 페이지 표시는 누락 검토를 막는다.
부분 응답의 유효 항목을 가져오는 것과 전체 누락 처리를 허용하는 것은 별개다.

## 후처리와 세션

DB commit 후 [EcampusNotificationUpdater.afterCommit](../../lib/presentation/services/ecampus_notification_updater.dart)가
마감 변경 + 기존 enabled 알림에만 재예약한다. 완료/삭제 전환은 취소 경로를 사용한다.
후처리 실패는 성공한 DB transaction을 rollback하지 않는다.

[가져오기 화면](../../lib/presentation/screens/sync/ecampus_sync_progress_screen.dart)은 시작 시 쿠키 정리·명시 로그인,
반영/종료·실패·취소에서 공통 _finishSession을 사용한다. 메모리 세션 제거·서버 로그아웃 시도·WebView 도메인 쿠키 정리 후 다음 실행에 재로그인한다.
현재 설정 화면에는 별도 세션 관리 메뉴가 없다. [보안 정책](../보안%20정책.md) 참고.

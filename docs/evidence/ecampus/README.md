# eCampus 가져오기 보완 검증 — 2026-10-30

기준 커밋: `bfbb467`. 기존 Flutter DB v6·Repository·NEW/CHANGED 처리 위에 보완했다.
스키마·마이그레이션·의존성은 변경하지 않았다. 기기 간 동기화는 작업 범위에서 제외했다.

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| [ecampus_models.dart](../../../lib/data/models/ecampus_models.dart) | MISSING 분류·기본 유지 결정·응답 완전성 표시 |
| [ecampus_sync_classifier.dart](../../../lib/data/services/ecampus_sync_classifier.dart) | active 원본과 이번 키의 차집합으로 누락 후보 생성 |
| [ecampus_todo_parser.dart](../../../lib/data/services/ecampus_todo_parser.dart) | 실제 HTML 파서의 EOF 오류·추가 페이지 징후로 누락 검토 가능 여부 판정 |
| [default_ecampus_sync_service.dart](../../../lib/data/services/default_ecampus_sync_service.dart) | 오류·불완전 응답에서는 누락 후보 생성을 생략 |
| [ecampus_sync_apply_service.dart](../../../lib/data/services/ecampus_sync_apply_service.dart) | 기존 transaction 안에서 누락 결정 반영, commit 이후 알림 콜백 |
| [ecampus_notification_updater.dart](../../../lib/presentation/services/ecampus_notification_updater.dart) | 마감이 바뀌고 enabled 알림이 있는 일정만 재예약, 완료·삭제 알림 취소 |
| [ecampus_sync_preview_screen.dart](../../../lib/presentation/screens/sync/ecampus_sync_preview_screen.dart) | 신규 제외와 변경 유지 의미 분리, 필드별 적용 유지, 누락 수동 검토 |
| [ecampus_sync_progress_screen.dart](../../../lib/presentation/screens/sync/ecampus_sync_progress_screen.dart) | 알림 후처리 연결, 매번 로그인, 반영·실패·취소 후 세션 종료 |
| [main_shell_screen.dart](../../../lib/presentation/screens/main/main_shell_screen.dart) | 세션 재사용 제거, 기존 알림 의존성 전달, 수동 정리 실패에도 메모리 세션 해제 |
| [http_ecampus_auth_service.dart](../../../lib/data/services/http_ecampus_auth_service.dart) | 로그아웃 오류·네트워크 실패에도 finally에서 로컬 쿠키 정리 |
| [in_app_webview_ecampus_cookie_store.dart](../../../lib/presentation/services/in_app_webview_ecampus_cookie_store.dart) | 일부 URL 정리 실패 시에도 나머지 URL 삭제 시도 |
| [ecampus_review_v6_test.dart](../../../test/data/services/ecampus_review_v6_test.dart) | 실제 Drift 메모리 DB로 반영·알림·누락·rollback·불완전 HTML 검증 |
| [ecampus_review_flow_test.dart](../../../test/presentation/screens/ecampus_review_flow_test.dart) | 검토 UI, 360px 화면, 정상·취소·조회 실패·저장 실패·로그아웃 실패·재로그인 경로 |
| [http_ecampus_auth_service_test.dart](../../../test/data/services/http_ecampus_auth_service_test.dart) | 서버·네트워크 로그아웃 실패 시 쿠키 정리 검증 |
| [database_v6_ui_test.dart](../../../test/presentation/screens/database_v6_ui_test.dart) | 기존 마감 필드 선택 테스트의 버튼 문구 변경 반영 |

## 동작

- `신규 선택 제외`는 NEW에만 적용한다. CHANGED의 제목·마감 체크를 모두 해제하고 `선택 반영`하면 사용자 값은 유지하고 원본 스냅샷만 갱신한다. 제목만·마감만·둘 다 적용도 기존 체크박스로 선택한다.
- 알림 API는 선택한 전체 DB transaction이 성공한 뒤 호출한다. 마감이 실제로 바뀌고 기존 enabled 설정이 있을 때만 재예약한다. OS 오류는 저장을 되돌리지 않고 별도 안내한다. 누락 완료·휴지통 이동 후에는 기존 예약을 취소한다.
- 반영 시도 종료(성공·실패) 즉시 세션 정리를 시작한다. 반영하지 않고 preview를 닫거나 로그인 취소·조회 실패·뒤로 가기로 종료한 경우에도 정리한다. 재시도·다음 가져오기는 기존 쿠키를 지운 후 다시 로그인한다. 서버 로그아웃 실패와 로컬 쿠키 삭제 실패는 구분해 실제 기기에서 확인해야 한다.
- 누락 검토는 active eCampus 일정만 보여준다. 기본은 유지이며 Task·원본 연결·스냅샷을 변경하지 않는다. 완료는 기존 `updateTaskStatus`, 삭제는 기존 `markDeleted`로 휴지통 이동한다. 여러 누락 반영도 기존 배치 transaction을 사용한다.
- 한 번의 반영 버튼이 transaction 단위다. preview 닫기가 앞서 성공한 반영을 취소하는 동작은 아니다.

## 초기 보완 검증 원본 (응답 오판정 수정 전)

- [테스트 원본](review-tests-20261030.jsonl): 기존 125건 + 추가 36건 = **161건 통과**.
- [정적 분석](review-analyze-20261030.txt): 오류·경고 0건, 기존 `onReorder` deprecation info 1건.
- [Android debug 빌드](review-build-20261030.txt): 성공. 실제 기기 설치·실행은 이번 작업에서 수행하지 않았다.
- [검증 요약·소스 및 APK 해시](review-summary-20261030.json).

```powershell
C:\flutter\bin\flutter.bat test --no-pub --concurrency=1 --machine test/data test/presentation
C:\flutter\bin\flutter.bat analyze --no-pub --no-fatal-infos
C:\flutter\bin\flutter.bat build apk --debug --no-pub
```

## 한계와 Android 직접 확인

- HTML에 전체 목록임을 증명하는 서버 계약은 없다. 구조상 정상인 일부 목록까지 모두 식별할 수는 없다. 오류·잘림·페이지 표식이 있으면 누락 검토를 생략하며, 그 외에도 자동 완료·삭제하지 않고 사용자 선택을 요구한다.
- 누락 `유지`의 검토 이력을 별도 저장하지 않는다. 원본이 계속 보이지 않으면 다음 가져오기에서 다시 검토 대상이 된다.
- 로그인 계정별 원본 범위 분리와 전체 조회·실패·취소 감사 이력은 이번에 추가하지 않았다.
- 알림 실패 재시도 큐는 추가하지 않았다. 알림 설정을 다시 저장하거나 앱 시작 시 기존 재예약 경로로 확인한다.
- 앱 강제 종료 시 서버 로그아웃 완료를 보장하지 않는다. 다음 가져오기는 로그인 전 로컬 쿠키 정리를 먼저 시도한다. OS/플러그인의 실제 쿠키 삭제와 알림 예약은 실기기에서 확인한다.

Android 확인 순서:

1. 새 APK를 설치한 뒤 NEW 가져오기·신규 제외·재가져오기 중복 방지를 확인한다.
2. 변경된 원본으로 현재 값 유지·제목만·마감만·둘 다 반영을 확인한다. 메모·태그·폴더가 유지돼야 한다.
3. 기존 enabled 알림이 있는 일정의 마감 변경 후 새 시각 예약과 옛 예약 취소를 확인한다. 알림 설정이 없거나 disabled인 일정에는 새 예약이 생기면 안 된다.
4. 누락 후보의 기본 유지, 명시적 완료, 삭제 후 휴지통 복원을 확인한다. 계속 누락된 완료·삭제 일정은 재검토 목록에서 제외돼야 한다.
5. 성공·반영 실패·WebView 취소·조회 중 뒤로 가기 이후 다시 가져오기를 열어 재로그인이 필요한지 확인한다. 서버 로그아웃 실패에서도 로컬 로그인 정보 정리 여부를 확인한다.

## 응답 완전성 오판정 수정 — 2026-10-30

사용자가 실기기에서 반복되는 ‘불완전한 응답’ 안내를 보고했다. 기존 구현은 원문에서 div 문자열 수를 세고, no_data·빈 pagination·값 없는 data-next-page가 존재해도 누락 검토를 막았다. 주석·스크립트의 문자열, 숨긴 빈 목록 안내와 비어 있는 페이지 이동 영역은 정상 목록에도 공존할 수 있어 오판정을 재현했다. 실제 사용자 응답 HTML은 수집하지 않았으므로 기기에서 어떤 조건이 걸렸는지는 확정하지 않았다.

- HTML5 파서의 실제 EOF 오류를 사용한다. 주석·스크립트의 태그 문자열, HTML에서 생략 가능한 body/html 닫는 태그는 단순 문자열 개수로 판단하지 않는다.
- no_data 안내의 공존과 비어 있는 paging 영역을 불완전 근거에서 제외한다. 실제 이동 가능한 링크·명시적인 추가 페이지 값은 계속 검토를 차단한다. 현재 페이지·비활성·숨긴 컨트롤은 제외한다.
- 정리된 고정 문구로 판정 이유를 표시한다. HTML 본문·사용자 이름·쿠키를 진단 기록에 저장하지 않는다. 문구는 조회된 항목을 가져올 수 있음을 안내하며, 모든 경우에 재조회를 강요하지 않는다.
- 정상 HTML 조합과 실제 잘림·추가 페이지의 회귀 테스트 12건을 추가했다. 기존 빈 paging 실패 fixture는 실제 다음 페이지 링크가 있는 응답으로 바꿨다.
- 전체 데이터·화면 테스트 **173건 통과**. [테스트 원본](response-check-fix-tests-20261030.jsonl), [분석](response-check-fix-analyze-20261030.txt), [Android 빌드](response-check-fix-build-20261030.txt), [검증 요약](response-check-fix-summary-20261030.json).

위 초기 검증 원본·APK 해시는 이전 시점 기록으로 유지한다. 실제 기기에서 수정 APK로 같은 응답의 경고 여부를 다시 확인해야 한다. 전체 원본 목록임을 증명하는 서버 계약이 없다는 한계와 자동 완료·삭제 금지 정책은 유지한다.

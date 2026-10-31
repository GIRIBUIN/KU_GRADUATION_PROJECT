# 모바일 홈 UI 개편 — 2026-10-30

UI-022 최신 보완: 제외 항목 작업은 체크 아이콘이며, 양쪽 선택 상단 높이/본문 여백을 줄였다. 최종 검증·캡처·소스 해시는 문서 맨 아래 height 기록을 기준으로 한다.

최신 UI-022: 휴지통·제외된 eCampus 항목의 체크 선택과 고정 상단을 통일했다. 검증은 문서 하단 ‘휴지통·제외 항목 체크 선택 상단 통일’을 본다. UI-021은 `b55d523`/`229771e`로 커밋됐으며 아래 미커밋 표시는 당시 기록이다. 이번 UI-022는 커밋·push하지 않았다.

최신 UI-021: 제외된 eCampus 항목을 별도 화면 대신 홈 공통 레이아웃으로 통합했다. 검증은 문서 하단 ‘제외된 eCampus 항목 홈 레이아웃 통일’을 본다. UI-020은 `baa73a9`/`ebdd5db`로 커밋됐으며 아래 미커밋 표시는 당시 기록이다. 이번 UI-021은 커밋·push하지 않았다.

최신 UI-020: 설정 화면을 컨텍스트 메뉴와 즉시 저장 하단창으로 교체했다. 최신 검증은 문서 하단 ‘설정 컨텍스트 메뉴·즉시 저장’를 본다. UI-017~019는 `b8cd8e9`~`12ed816`으로 커밋되어 원격에 반영됐고, 아래의 미커밋 표시는 각 작업 당시 기록이다. 이번 UI-020은 커밋·push하지 않았다.

최신 UI-019: 보관/복원 기능은 제거했고 데이터 전환도 하지 않는다. 목록/태그 숨김은 각각 작은 이름·눈 아이콘 팝업으로 바뀌었다. 아래 UI-018의 보관 복원 설명은 해당 시점 기록이며 최신 동작은 문서 하단 UI-019를 기준으로 한다. 아직 커밋하지 않았다.

추가 변경 UI-018: 일반 기간의 전체 선택 제거, 할 일 구역명, 컨텍스트 메뉴/드래그 분류, 휴지통 전용 전체 기간은 문서 하단에 기록한다. UI-017의 정책 중 이 부분은 UI-018이 최신이다. 아직 커밋하지 않았다.

추가 변경(2026-10-31): 기간 영구 저장·Drawer의 기간/전체 분리·설정의 중복 화면 제거는 문서 하단 ‘기간 복원·Drawer 전체 조회’에 기록한다. 앞선 재실행 시 오늘 초기화 정책은 이번부터 마지막 선택 복원으로 바뀐다. 이 추가 변경은 아직 커밋하지 않았다.

최신 정리(2026-10-31): 후속 UI 변경은 `f3a6735`~`80f4660`의 11개 코드 커밋으로 분리되어 원격 브랜치에 반영됐다. [현재 커밋 목록](../../커밋%20정리%202026-10-31.md)과 [최종 검증 요약](../commits/ui-final-verification-20261031.json)을 함께 본다. 아래 기록과 summary의 `uncommitted_changes`, ‘커밋 미수행’은 각 측정 당시 상태다. 중간 실패 로그도 원본으로 보존하며 최종 통과 로그와 구분한다. 캡처는 widget 테스트 렌더이며 실제 학교 계정·Android 설치 검증을 뜻하지 않는다.

범위: 홈 정보 구조·탐색·보기 조정·빠른 추가. 이번 작업 시작 시 실제 DB는 **v7**이었으며 스키마·이관·eCampus 서비스·검토·MISSING·세션 종료·알림 후처리·repository 메서드 계약은 변경하지 않았다. 기기 간 동기화는 추가하지 않았다.

## 변경 파일

| 파일 | 역할 |
| --- | --- |
| [mobile_home_page.dart](../../../lib/presentation/screens/main/mobile_home_page.dart) | 신규 홈 본문, Drawer scope, 날짜/기간, 보기 조정 Bottom Sheet, 단순 Task row |
| [main_shell_screen.dart](../../../lib/presentation/screens/main/main_shell_screen.dart) | 홈·빠른 추가·캘린더 navigation, 실제 메타데이터 조회와 기존 작업 콜백 연결, 설정 내 기존 관리 화면 진입 |
| [task_create_screen.dart](../../../lib/presentation/screens/task/task_create_screen.dart) | 같은 State·저장 함수의 빠른 추가 모드, 작성 중인 제목·마감·목록·태그를 전체 생성 화면에 전달 |
| [home_view_options.dart](../../../lib/data/models/home_view_options.dart) | 정렬·상태·우선순위·태그 선택과 설정 직렬화 |
| [settings_repository.dart](../../../lib/data/repositories/settings_repository.dart) | 기존 AppSettings에 homeView 값 추가. Repository 메서드 변경 없음 |
| [metadata_mappers.dart](../../../lib/data/local/mappers/metadata_mappers.dart) | 기존 key/value 설정 테이블의 homeView 키 읽기·쓰기. 테이블/컬럼 추가 없음 |

## 동작과 재사용

- Drawer는 전체·고정 수집함·실제 목록·전역 태그·완료·휴지통을 선택한다. 선택 행을 강조하고 설정은 하단에 둔다. 폴더는 소속 목록을 펼치고 접는 보관함이다. 폴더를 눌러도 현재 조회 범위·기간·Task 결과는 바꾸지 않는다. Task를 보려면 안의 목록을 선택한다.
- 상단 기간은 오늘·월요일 시작 이번 주·이번 달·연월일 선택이다. Drawer와 기간 상태는 홈 State에서 유지하며 재실행 시 전체·오늘로 시작한다. 캘린더 탭 이동은 선택을 지우지 않는다.
- 사용자 확인에 따라 기간은 첫 섹션과 완료 섹션에 적용한다. 임박·지남은 같은 Drawer scope의 전체 미완료 Task에서 보여준다. 임박은 기존 `isTaskUrgent`와 `urgentDueDays`, 지남은 `isTaskOverdue`를 재사용한다. 한 Task가 기간 섹션과 보조 섹션에 함께 표시될 수 있으며 각 count는 그 섹션의 실제 표시 수다.
- 마감 없는 미완료 Task는 첫 섹션에 표시한다. 완료의 기간은 completedAt, 없으면 dueDate/updatedAt을 사용한다. 휴지통은 deletedAt, 없으면 dueDate/updatedAt으로 기간을 정한다.
- 보기 조정은 기존 Task 필드로 정렬 5개·상태 2개·우선순위 3개·실제 태그 복수 선택을 지원한다. 여러 태그는 OR, scope와 다른 필터는 AND다. 상태는 기본 미완료+완료, 우선순위·태그는 미선택 시 제한 없음이다. 휴지통은 상태 필터를 적용하지 않는다.
- 값 변경·기본값 초기화는 즉시 홈에 반영한다. 저장 버튼만 최신 AppSettings를 읽고 homeView를 병합해 저장한다. 미저장 변경은 홈 State에만 남고 다른 설정 저장·화면 이동으로 영구 저장되지 않는다. 저장 실패는 안내하고 sheet를 유지한다.
- Task 탭·완료·복원·영구 삭제는 기존 MainShell 콜백을 호출한다. 알림 예약/취소와 위젯 갱신 경로를 그대로 사용한다. eCampus 버튼도 기존 `_openEcampusSync`를 호출하며 표시 이름만 ‘가져오기’로 구분한다.
- 중앙 +는 `TaskCreateScreen(quickAdd: true)`를 Bottom Sheet로 연다. 제목만 저장할 수 있고 기본 목록은 수집함이다. 선택 입력은 마감·목록·태그다. `_saveTask`의 기존 atomic 저장·알림 설정·commit 후 OS 예약을 두 생성 UI가 공유한다. 상세 설정으로 이동할 때 draft만 전달하며 미리 DB에 생성하지 않는다.
- 기존 목록·태그 관리와 전체 일정 수동 순서/일괄 처리는 설정의 ‘목록·태그 관리’·‘전체 일정 관리’에서 유지한다. 옛 홈 카드의 배치·태그 전용 섹션 대신 새 고정 섹션과 보기 조정을 사용한다. 옛 설정 값·설정 화면 독립 테스트는 보존했다.

## 검증

- 데이터·화면 회귀 **201건 통과**: 기존 190건에서 새 홈 UI 10건·설정 호환 1건 추가. 기존 홈 전용 테스트는 요청한 새 구조에 맞춰 수정했고 주간 위젯 반영·캘린더 생성/수정/삭제·목록 관리 검증을 유지했다.
- [전체 테스트 원본](home-tests-20261030.jsonl), [최종 캡처 보조 코드의 UI 10건 재확인](capture-tests-20261030.jsonl).
- [정적 분석](analyze-20261030.txt): 오류·경고 0건, 기존 onReorder deprecation info 1건.
- [Android debug APK 빌드](build-20261030.txt): 성공. [검증 요약·소스/APK 해시](summary-20261030.json).
- 테스트는 실제 Drift 메모리 DB와 기존 Repository를 사용하고 OS 알림/위젯 플랫폼만 대체했다. 설정 저장은 파일 DB를 닫고 다시 열어 복원까지 확인했다. 실제 계정 로그인·실기기 알림·Android 키보드 조작 성공을 뜻하지 않는다.
- UI 테스트: [신규 홈](../../../test/presentation/screens/mobile_home_test.dart), [홈/캘린더/위젯 회귀](../../../test/presentation/screens/main_shell_home_layout_test.dart), [기존 목록 관리 진입 변경](../../../test/presentation/screens/list_groups_test.dart), [설정 실제 저장·재개방·호환](../../../test/data/repositories/drift_metadata_repositories_test.dart).

테스트 재실행:

```powershell
C:\flutter\bin\flutter.bat test --no-pub --concurrency=1 test/data test/presentation
C:\flutter\bin\flutter.bat analyze --no-pub --no-fatal-infos
C:\flutter\bin\flutter.bat build apk --debug --no-pub
```

캡처는 `--dart-define=CAPTURE_UI=true`를 준 UI 테스트에서만 생성한다. [홈](home.png) · [Drawer](drawer.png) · [보기 조정](view-options.png) · [빠른 추가](quick-add.png). 360×1000 논리 픽셀, 테스트 데이터, Windows 맑은 고딕과 MaterialIcons를 사용한 widget 렌더다. Android 캡처가 아니며 앱에 폰트·의존성을 추가하지 않았다. 테스트 기본 Ahem 폰트가 AppBar/navigation에 남지 않도록 캡처용 theme에만 폰트를 지정했다.

`tests-20261030.jsonl`은 최초 캡처의 가상 시간 대기로 중단된 실행 원본이다. 최종 통과 결과로 사용하지 않는다. 이후 캡처 I/O는 `tester.runAsync`로 분리했다.

## Android 직접 확인

1. 새 APK를 기존 앱 위에 설치하고 기존 일정·완료·휴지통·폴더·목록·태그가 유지되는지 확인.
2. Drawer에서 학교 폴더를 펼치고 과목 목록·태그를 선택해 오늘/이번 주/이번 달/특정 연월일을 함께 적용. 폴더 접기·펼치기는 조회 범위를 바꾸지 않아야 한다. 캘린더 왕복 후 선택 유지 확인.
3. 보기 조정의 5개 정렬·상태·우선순위·여러 태그를 조합. 미저장 변경 후 앱 완전 종료 시 복귀, 저장 후 종료 시 복원, 초기화의 임시/저장 차이 확인.
4. 오늘·임박·지남·완료의 제목/개수, 마감 없는 Task, 긴 제목·많은 태그·큰 글씨 확인. 섹션별 중복 표시 가능 여부도 확인.
5. 홈 완료/해제와 상세 수정 후 기존 알림·위젯 갱신 확인. 휴지통 복원 후 원래 목록 유지 확인.
6. 중앙 +에서 키보드가 열린 상태로 제목만 추가, 마감/목록/태그 추가, 상세 설정 이동·저장·취소·뒤로 가기 확인. 두 번 생성되지 않아야 함.
7. 기존 캘린더 생성·수정·삭제, 설정의 목록·태그 관리, eCampus 가져오기→검토→반영→재로그인 흐름 확인.

이번 APK는 기기에 설치하지 않았고 변경은 아직 커밋하지 않았다.

## 폴더 역할 정정 — 2026-10-30

초기 홈 구현은 폴더를 Task 합산 조회 범위로 연결했다. 사용자 확인에 따라 이 연결을 제거했다. 현재 폴더는 목록을 펼치고 접는 용도이며 Task 조회는 목록을 선택했을 때만 바뀐다. 폴더의 펼침 상태는 현재 실행 중 Drawer 재개방에도 유지한다.

- 변경: `mobile_home_page.dart`, `mobile_home_test.dart`와 이 기록. DB·repository·eCampus·기존 관리 화면은 변경하지 않았다.
- 수집함은 기본 목록 하나다. 전체는 수집함을 포함한 모든 목록의 Task를 모아 보는 버튼이다. 범위를 고른 뒤의 기간·보기 필터 동작은 유지한다.
- [관련 UI 10건 통과](folder-only-final-tests-20261030.jsonl): 폴더 펼침·접기 중 Drawer 유지, 전체 선택과 Task 결과 불변, 목록을 눌렀을 때만 조회 변경, 목록 선택과 기간 조합, 다시 Drawer를 열었을 때 선택·펼침 유지까지 확인했다.
- [정적 분석](folder-only-analyze-20261030.txt) 오류·경고 0건(기존 info 1건), [APK 빌드](folder-only-build-20261030.txt) 성공, [요약·소스/APK 해시](folder-only-summary-20261030.json).
- 최신 widget 캡처: [홈](folder-only-home.png) · [Drawer](folder-only-drawer.png) · [보기 조정](folder-only-view-options.png) · [빠른 추가](folder-only-quick-add.png). 앞선 캡처와 201건 검증은 이전 구현 시점 기록으로 보존한다.
- `folder-only-tests-20261030.jsonl`은 펼쳐진 ExpansionTile의 전체 영역 중앙을 탭해 하위 목록이 눌렸던 최초 테스트 원본이다. 최종 테스트는 실제 폴더 제목을 눌러 접기·펼치기를 검증하며 위 `folder-only-final-tests`를 기준으로 한다.
- 직접 확인: 새 APK 설치 → Drawer의 학교 폴더를 두 번 눌러 목록만 펼침·접힘 확인 → 운영체제 목록을 눌러 해당 Task 조회 → Drawer 재개방 후 선택 및 펼침 유지 확인. APK 설치·커밋은 미수행이다.

## 하단 아이콘·Drawer 스와이프 확인 — 2026-10-30

- 하단 navigation의 ‘홈 / + / 캘린더’ 글씨는 숨기고 아이콘만 표시했다. 접근성 이름·길게 누르기 tooltip은 ‘홈 / 빠른 추가 / 캘린더’로 유지한다. 화면 이동과 빠른 추가 저장 경로는 동일하다.
- 홈 Scaffold의 기본 왼쪽 가장자리 드래그 열기를 명시했다. 화면 가운데 전체에 별도 수평 제스처를 덧붙이지 않았다. 메뉴 버튼·왼쪽 가장자리→오른쪽 스와이프로 열고, 열린 Drawer를 왼쪽으로 밀어 닫을 수 있다.
- 변경은 MainShell navigation, MobileHomePage Drawer 옵션과 연결 UI 테스트 3개다. 기존 문구로 버튼을 찾던 테스트는 안정적인 navigation key를 사용하도록 바꿨다.
- [관련 UI 23건 통과](icon-nav-final-tests-20261030.jsonl): 아이콘 아래 label의 실제 opacity 0, 가장자리 스와이프 열기·닫기와 선택 유지, 빠른 추가·캘린더·위젯·목록 관리 회귀 확인. [분석](icon-nav-analyze-20261030.txt) 오류·경고 0건(기존 info 1건), [APK 빌드](icon-nav-build-20261030.txt) 성공. [요약·소스/APK 해시](icon-nav-summary-20261030.json).
- 최신 widget 캡처: [홈](icon-nav-home.png) · [스와이프로 연 Drawer](icon-nav-drawer-swipe.png) · [보기 조정](icon-nav-view-options.png) · [빠른 추가](icon-nav-quick-add.png). 기존 캡처는 해당 시점 기록으로 보존한다.
- `icon-nav-tests-20261030.jsonl`은 숨겨진 label Text가 트리에 남는 Flutter 동작을 ‘Text 없음’으로 검사해 실패한 최초 원본이다. 최종 검증은 label의 실제 FadeTransition opacity를 확인한다.
- Android 직접 확인: 새 APK 설치 → 하단 글씨 없음 확인 → 세 아이콘 동작 확인 → 홈의 왼쪽 가장자리를 오른쪽으로 밀어 Drawer 열기 → 왼쪽으로 밀어 닫기. 설치·커밋은 미수행이다.

## Drawer 선택 배경의 설정 영역 비침 수정 — 2026-10-31

- 휴지통 선택 후 스크롤할 때 파란 선택 배경이 하단 고정 설정 뒤로 그려지는 문제를 재현했다. ListTile의 Ink 배경이 스크롤 바깥 Drawer Material에 그려져 viewport의 clipping을 벗어나는 구조였다.
- 스크롤 목록에 투명 Material을 두고 그 바깥을 ClipRect로 제한했다. 선택 배경·눌림 효과가 해당 스크롤 영역 안에서만 그려지며, 설정과 상단 타이틀로 번지지 않는다. 색상·선택 상태·클릭 처리·DB·eCampus는 변경하지 않았다.
- 변경 코드: `mobile_home_page.dart`와 `mobile_home_test.dart`. 태그 16개를 추가한 360×650 화면에서 휴지통 선택 후 아래로 드래그하고, 설정 영역의 빈 픽셀이 원래 Drawer 배경색과 같은지 검사했다. 설정 위치 고정과 실제 설정 진입도 확인한다.
- [수정 전 실패 원본](footer-before-tests-20261030.jsonl): 설정 영역의 픽셀이 파란 선택색과 섞여 기대 배경색과 달랐다. [수정 후 홈 UI 12건 통과](footer-final-tests-20261031.jsonl). [설정 영역 캡처](footer-drawer-footer.png).
- 검증 도중 자정을 넘어, 테스트 파일 최초 로드 시 한 번 만든 기준 날짜가 전날로 남는 fixture 문제도 드러났다. 테스트마다 기준 날짜를 새로 만들도록 수정했다. 앱 날짜 처리 코드는 변경하지 않았다. `footer-final-tests-20261030.jsonl`은 이 중간 실행이며 최종 결과는 20261031 파일이다.
- [분석](footer-analyze-20261031.txt) 오류·경고 0건(기존 info 1건), [APK 빌드](footer-build-20261031.txt) 성공. [요약·소스/APK 해시](footer-summary-20261031.json).
- 직접 확인: 새 APK 설치 → 휴지통 선택 → Drawer 재개방 → 목록을 아래로 밀어 선택 행을 설정 쪽으로 이동 → 설정 뒤에 파란색이 비치지 않는지 확인. 실제 기기 설치·커밋은 미수행이다.

## Drawer 명칭·추가 아이콘 정리 — 2026-10-31

- 앱의 기본 목록 표시명을 ‘수집함’에서 ‘미지정’으로 통일했다. 내부 ID `kutodo:inbox`와 Task 연결·고정 목록 제약은 유지한다. 공통 FolderMapper는 기존 DB에 옛 이름이 남아 있어도 같은 기본 목록 ID를 새 이름으로 표시한다. 신규 DB/이관의 기본 목록 생성도 새 표시명을 사용한다. 스키마 버전·SQL 구조·이관 알고리즘은 변경하지 않았다.
- Drawer ‘폴더’ 구역 제목을 ‘목록’으로 변경하고 오른쪽에 숨김 보기/가리기·폴더 추가·목록 추가 아이콘을 배치했다. 태그 제목 오른쪽에는 태그 추가 아이콘을 뒀다. ‘보관’ 제목은 ‘기타’, 완료 아이콘은 네모 체크박스로 바꿨다.
- 추가는 기존 ManagementPage의 생성 대화상자·저장 handler를 MainShell이 함께 호출한다. 별도 CRUD 경로를 만들지 않았다. 목록 생성은 최신 폴더 데이터를 읽어 소속 폴더를 선택하고 저장한다. Drawer는 생성 후에도 열려 있으며 실제 데이터로 갱신된다.
- 숨김 아이콘은 기존 hiddenFolderIds/hiddenTagIds 설정을 기준으로 메뉴에서 숨겨진 목록·태그를 잠시 표시하거나 가린다. 이 토글은 실행 중 상태이며 Task 결과나 저장된 숨김 설정은 변경하지 않는다. 미지정은 고정 목록이라 숨김 목록에 ID가 남아 있어도 항상 표시한다. 폴더 클릭은 기존 펼침·접기를 유지한다.
- 코드 변경: `list_defaults.dart`, `metadata_mappers.dart`, `schema_v7_migration.dart`의 기본 이름 인자, `drift_folder_repository.dart`의 기본 이름 검증·안내, `main_shell_screen.dart`, `mobile_home_page.dart`. 현재 DB 안내 1개·관련 테스트 4개도 갱신했다. 과거 증거의 옛 용어는 시점 기록으로 보존한다.
- 신규 검증 3건: Drawer의 폴더·소속 목록·태그 실제 생성, 숨김 토글의 표시·선택·설정 보존, 기존 이름이 저장된 DB의 표시/색상 편집/Task 연결 보존. 전체 데이터·화면 **206건 통과**. [테스트 원본](metadata-nav-tests-20261031.jsonl), [정적 분석](metadata-nav-analyze-20261031.txt), [Android 빌드](metadata-nav-build-20261031.txt), [요약·소스/APK 해시](metadata-nav-summary-20261031.json).
- 정적 분석 오류·경고 0건(기존 info 1건), Android debug APK 빌드 성공. eCampus 서비스·검토·알림·세션 종료 코드는 변경하지 않았다.
- 최신 캡처: [Drawer 제목과 아이콘](metadata-nav-drawer-actions.png) · [홈](metadata-nav-home.png) · [빠른 추가](metadata-nav-quick-add.png) · [하단 비침 회귀](metadata-nav-drawer-footer.png).
- Android 직접 확인: 기존 DB로 새 APK 설치 → 메뉴·빠른 추가·상세·가져오기 선택에서 미지정 표시 확인 → 목록/태그 제목의 추가 아이콘으로 실제 생성 → 숨김 보기/가리기와 폴더 펼침 확인 → 기타·네모 완료 아이콘 확인. 설치·커밋은 미수행이다.

## 단일 날짜·구간 기간 선택 — 2026-10-31

- 날짜 메뉴를 ‘오늘 / 이번 주 / 이번 달 / 전체 / 기간 선택’ 순서로 변경했다. 기간 선택에서는 ‘단일 날짜’와 ‘날짜 구간’을 고른 뒤 기존 Material 날짜 선택 UI를 사용한다. 같은 날을 시작·종료로 지정해도 하루 조회가 가능하다.
- 구간은 시작일 00:00부터 종료일의 마지막 시간까지 포함한다. 홈 상단·첫 섹션·전체 목록 Drawer 항목은 선택한 날짜/구간을 표시한다. 취소하면 이전 선택을 유지하며, 캘린더 왕복에도 유지한다. 앱 재실행 시 오늘로 돌아오는 기존 정책은 유지한다.
- 코드 변경은 `mobile_home_page.dart`, 관련 테스트는 `mobile_home_test.dart`다. 목록/태그 범위·저장한 보기 필터를 함께 적용한다. 마감 임박·지남은 기존 정책대로 실제 현재 시각 기준이며, DB·repository·eCampus·알림 코드는 변경하지 않았다.
- [홈 UI 18건 통과](custom-period-tests-20261031.jsonl). 신규 3건은 구간 양끝 포함·바깥 날짜 제외, 동일 날짜 구간, 선택 취소를 확인한다. 기존 단일 날짜 테스트는 새 진입 경로와 재실행 초기화를 검증한다. [캡처 포함 동일 18건 통과](custom-period-capture-tests-20261031.jsonl)는 별도 실행이며 총 36개의 서로 다른 테스트를 뜻하지 않는다.
- [정적 분석](custom-period-analyze-20261031.txt) 오류·경고 0건(기존 onReorder deprecation info 1건), [Android debug 빌드](custom-period-build-20261031.txt) 성공. [요약·소스/APK 해시](custom-period-summary-20261031.json).
- widget 렌더: [단일 날짜](custom-period-same-day.png) · [날짜 구간](custom-period-range.png). 기존 캡처는 보존한다. Android 직접 확인: 기간 선택에서 하루/여러 날 선택 → 마지막 날의 일정 포함 확인 → 취소 시 선택 유지 → 캘린더 왕복 시 유지 → 앱 완전 종료·재실행 시 오늘 확인. 기기 설치·이번 변경 커밋은 수행하지 않았다.

## Drawer 개별 숨김 관리·길게 누르기 — 2026-10-31

- 숨김 아이콘은 개별 목록·태그의 숨김 스위치가 있는 Bottom Sheet를 연다. 미지정은 항상 표시하고 스위치를 비활성화한다. 숨김은 Task 삭제/보관/필터가 아닌 메뉴 표시 설정이다. 선택 중인 목록을 숨겨도 해당 조회와 Task 소속은 유지한다.
- 기존 `AppSettings.hiddenFolderIds/hiddenTagIds`를 사용한다. 저장할 때 최신 설정을 읽고 해당 ID 하나의 변경만 합쳐 다른 숨김·정렬·필터·알림 설정을 보존한다. 저장 중에는 스위치를 잠그고, 실패하면 기존 표시값을 유지하며 오류 문구로 재시도를 안내한다.
- 폴더 길게 누르기 → 폴더 편집 / 목록 추가(해당 폴더 미리 선택). 목록 길게 누르기 → 목록 편집 / 할 일 추가(해당 목록 미리 선택). 태그 길게 누르기 → 태그 편집 / 할 일 추가(해당 태그 미리 선택, 목록은 미지정).
- MainShell의 기존 관리 State에 편집을 위임하고 목록 추가 대화상자에 초기 폴더 인자만 추가했다. TaskCreateScreen은 초기 목록·태그 인자를 받아 기존 빠른 추가 저장 함수를 사용한다. 상세 설정 이동에서도 분류를 유지한다. 분류만 미리 선택된 빈 작성창은 바로 닫을 수 있으며, 입력·분류를 바꾸면 기존 작성 취소 보호가 동작한다.
- 변경 코드: `mobile_home_page.dart`, `main_shell_screen.dart`, `task_create_screen.dart`. 관련 테스트는 `mobile_home_test.dart`다. DB·repository contract·eCampus·알림·제스처 범위·기존 Task 상세는 변경하지 않았다. 이전 기간 선택 변경은 함께 작업 폴더에 남아 있으나 [직전 스냅샷](custom-period-summary-20261031.json)과 비교해 이번 변경 범위를 별도로 확인한다.
- [관련 화면 33건 통과](drawer-actions-final-tests-20261031.jsonl): 홈 UI 21건, 기존 홈/캘린더/위젯 회귀와 목록 관리 12건. 개별 숨김/표시·미지정 보호·다른 설정 보존·재실행 유지, 폴더 편집과 소속 목록 생성, 하위 목록의 길게 누르기가 상위 폴더 메뉴를 열지 않는지, 목록/태그 편집과 실제 Task 저장·상세 생성 전달을 검증했다.
- [최초 테스트 원본](drawer-actions-tests-20261031.jsonl)은 가상 ListView에서 아직 만들어지지 않은 태그 스위치에 ensureVisible을 호출해 실패했다. 최종 테스트는 먼저 목록을 스크롤해 위젯을 만든 뒤 실제 탭을 검증한다. [캡처용 관련 2건](drawer-actions-capture-tests-20261031.jsonl)은 위 33건의 일부를 다시 실행한 것이다.
- [정적 분석](drawer-actions-analyze-20261031.txt) 오류·경고 0건(기존 onReorder deprecation info 1건), [Android debug 빌드](drawer-actions-build-20261031.txt) 성공. [요약·소스/APK 해시](drawer-actions-summary-20261031.json). widget 캡처: [개별 숨김 관리](drawer-actions-visibility.png) · [목록 길게 누르기 메뉴](drawer-actions-list-actions.png).
- Android 직접 확인: 숨김 관리에서 목록/태그 숨김·다시 표시 → 앱 재실행 후 유지 확인 → 미지정은 숨기기 불가 확인 → 폴더 길게 누르기에서 이름 수정·소속 목록 생성 → 목록/태그 길게 누르기에서 편집·할 일 추가 → 실제 저장 분류 확인 → 상세 설정으로 이동해도 선택 유지 확인 → 입력 없이 닫기와 입력 후 취소 확인. 기기 설치·이번 변경 커밋은 미수행이다.

## 홈 안쪽에서 Drawer 열기 — 2026-10-31

- `MobileHomePage`의 Scaffold에 `drawerEdgeDragWidth: MediaQuery.sizeOf(context).width` 한 줄을 추가했다. 홈 가장자리뿐 아니라 가운데 Task 행에서 시작한 오른쪽 스와이프도 기본 Drawer가 처리한다. 별도 제스처 인식기·애니메이션·데이터 변경을 추가하지 않았다. 짧고 느린 드래그는 기본 거리 기준에 따라 닫히고, 충분한 거리 또는 오른쪽 fling이면 열린다.
- [수정 전 재현](interior-drawer-before-tests-20261031.jsonl): 가장자리는 열리지만 화면 안쪽의 행 드래그 후 Drawer가 없었다. [최종 홈 UI 22건 통과](interior-drawer-verified-tests-20261031.jsonl): 기존 21건 중 열기 테스트를 확장하고, 세로 스크롤/반대 드래그/체크박스/상세 탭 보호 1건을 추가했다. 위젯 캡처: [안쪽 스와이프로 연 메뉴](interior-drawer-drawer-interior.png).
- `interior-drawer-final-tests-20261031.jsonl`은 중간 실행이다. 느린 170px 이동은 기본 Drawer 열림 거리보다 짧아 다시 닫혔고, 기본 Task 조회가 완료 항목을 제외한다는 점을 테스트 기대값에 반영하지 못했다. 최종 테스트는 실제 빠른 150px 오른쪽 fling으로 열기를 확인하고, 완료 Task는 ID로 별도 조회해 보존을 검증한다.
- [정적 분석](interior-drawer-analyze-20261031.txt) 오류·경고 0건(기존 onReorder deprecation info 1건), [Android debug 빌드](interior-drawer-build-20261031.txt) 성공. [요약·소스/APK 해시](interior-drawer-summary-20261031.json). 이번 소스 변경은 홈 코드·홈 테스트 2개로, [직전 Drawer 기능 스냅샷](drawer-actions-summary-20261031.json)과 비교한다.
- Task 행의 삭제/완료 스와이프 액션은 아직 구현되지 않았다. 이번에는 반대 방향 드래그가 Task를 수정하지 않는 것을 검증했다. 이후 액션을 넣을 때 Drawer와 행 스와이프의 우선순위를 함께 조정해야 한다. DB·repository·eCampus·알림 코드는 변경하지 않았다.
- Android 직접 확인: 가운데 Task 제목이나 빈 공간에서 오른쪽 스와이프 → 열린 메뉴 왼쪽 스와이프로 닫기 → 선택한 목록 유지 → 위아래로 스크롤할 때 메뉴가 열리지 않는지 → 체크박스/Task 탭/상단 날짜/조정/하단 캘린더·빠른 추가 확인. 기기 설치·이번 변경 커밋은 미수행이다.

## Task 상세 Bottom Sheet — 2026-10-31

- `MainShellScreen._openTaskDetail`을 페이지 push에서 `showModalBottomSheet`로 변경했다. 높이는 안전 영역의 90%이며 위쪽 배경이 보이고 모서리를 잘라 표시한다. 홈·캘린더·목록/태그 관리·전체 일정 관리·eCampus 검토의 공통 상세 callback은 같은 창을 사용한다.
- 기존 `TaskDetailScreen`의 Scaffold·스크롤 폼을 그대로 재사용하고 상단에 닫기 버튼을 추가했다. 제목·마감·우선순위·알림·목록·태그·메모·서브 작업 기능을 다시 만들지 않았다. 내부 Scaffold가 키보드 인셋을 처리한다.
- 기존 정책대로 저장 버튼, 닫기 버튼, Android 뒤로 가기 모두 `_saveTask(popAfterSave: true)`를 거친다. 바깥 터치·아래 드래그 닫기는 비활성화해 저장 우회를 막고, 드래그 손잡이도 표시하지 않는다. 저장 중 닫기/저장 버튼은 비활성화한다. DB 실패 시 창을 유지하고 오류를 표시하며 재시도한다. Task+알림 설정 transaction, commit 뒤 OS 예약, 종료 뒤 홈/메타데이터/위젯 갱신 코드는 유지한다.
- 변경 앱 파일: `main_shell_screen.dart`, `task_detail_screen.dart`. 테스트: `mobile_home_test.dart`, `main_shell_home_layout_test.dart`. DB·repository contract·eCampus·기존 저장/알림 서비스·Task row는 변경하지 않았다. [직전 스냅샷](interior-drawer-summary-20261031.json)과 비교해 이번 변경 범위를 확인한다.
- [관련 화면 36건 통과](detail-sheet-final-tests-20261031.jsonl): 홈 24건 + 기존 홈/캘린더/위젯·목록 관리 12건. 신규 2건은 실제 Drift DB로 하단 폼·키보드 인셋·여러 필드 저장·알림 예약 호출을 검증하고, 알림 설정 저장에 실패를 주입해 Task 변경 롤백·OS 예약 미호출·창 유지·재시도 후 정상 종료를 확인한다. 기존 캘린더 생성/상세 수정 테스트에는 BottomSheet 내부 진입 assertion을 보강했다.
- [최초 테스트 원본](detail-sheet-tests-20261031.jsonl)은 테스트 렌더 크기와 플랫폼 MediaQuery 크기의 불일치로 시간 선택창이 가로 배치되고, 키보드 인셋 변경 후 아직 만들어지지 않은 메모 필드를 찾으면서 실패했다. 새 키보드 테스트에만 실제 viewport 크기를 맞추고, 폼을 스크롤해 필드를 만든 뒤 검증했다. 앱의 날짜/키보드 로직을 변경해 테스트를 통과시키지 않았다.
- [캡처용 관련 2건 통과](detail-sheet-capture-tests-20261031.jsonl)는 위 36건의 일부 재실행이다. [상세창 widget 렌더](detail-sheet-detail-sheet.png). 키보드 검증은 260px 가상 인셋이며 실제 Android IME 캡처가 아니다. [정적 분석](detail-sheet-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건), [Android debug 빌드](detail-sheet-build-20261031.txt) 성공, [요약·소스/APK 해시](detail-sheet-summary-20261031.json).
- Android 직접 확인: 홈/캘린더/과목 목록의 Task를 눌러 동일 상세창 확인 → 제목·마감·알림·목록·태그·메모·서브 작업 수정 → 키보드가 열린 채로 저장/닫기 → 뒤로 가기로 저장 후 종료 → 완료·휴지통 Task의 상태/소속 보존 → 알림·위젯 갱신 확인. 바깥 터치·아래 드래그는 창을 닫지 않아야 한다. 기기 설치·이번 변경 커밋은 미수행이다.

## 홈 Task row 제목·줄바꿈·경로 — 2026-10-31

- `MobileHomePage._taskRow`에서 제목 크기 15→13, 제목의 2줄 제한과 분류의 1줄 제한·말줄임을 제거했다. 둘 다 줄바꿈되며 ListTile이 내용에 맞게 높아진다. 마감/우선순위·완료 체크박스·상세·휴지통 메뉴 callback은 유지한다.
- 경로는 `폴더 > 목록`, 경로와 태그 및 태그 사이는 ` · `로 구분한다. 예: `학교 > 운영체제 · #개인 · #과제`. 폴더 없는 경우 `개인 목록 · #과제`, 기본 목록은 `미지정`으로 표시한다. 기존 태그 순서를 유지하며 DB 데이터는 바꾸지 않는다.
- 변경 파일: `mobile_home_page.dart`, `mobile_home_test.dart`. 기존 홈의 기간/임박/지남/완료/휴지통은 같은 row 구현을 사용한다. 캘린더·전체 일정 관리 등 별도 row 구현은 이번 홈 표시 변경 대상이 아니다. [직전 상세창 스냅샷](detail-sheet-summary-20261031.json)과 비교해 이번 소스 변경 2개를 확인한다.
- [홈 UI 26건 통과](task-row-final-tests-20261031.jsonl). 신규 2건은 360px 폭에서 기본/1.5배 글씨로 RenderParagraph의 실제 줄 수(제목 3줄 이상), 말줄임 없음, 끝부분의 선택 영역 존재, 짧은 row보다 큰 높이, 긴 태그 줄바꿈, 경로 형식과 상세 진입 후 원래 제목·목록·태그 보존을 검증했다. 기존 완료/해제·복원·상세창·드래그·정렬/필터·빠른 추가·가져오기 진입 회귀도 포함한다.
- [수정 전 테스트](task-row-before-tests-20261031.jsonl)는 기존 제목 크기 15에서 실패했다. [캡처용 2건 통과](task-row-capture-tests-20261031.jsonl)는 신규 2건의 재실행이다. widget 렌더: [기본 글씨](task-row-wrapped-tasks.png) · [1.5배 글씨](task-row-wrapped-tasks-large.png).
- [정적 분석](task-row-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건), [Android debug 빌드](task-row-build-20261031.txt) 성공. [요약·소스/APK 해시](task-row-summary-20261031.json).
- Android 직접 확인: 긴 제목/여러 태그를 가진 Task의 끝부분 확인 → 시스템 글씨 확대 후 줄바꿈·스크롤 확인 → 폴더/목록 경로와 태그 구분 확인 → 체크박스 완료/해제·상세 진입·휴지통 메뉴 확인. 기기 설치·이번 변경 커밋은 미수행이다.

## 홈 Task 스와이프 동작 설정 — 2026-10-31

- 설정 → 편집 → 스와이프 동작에서 일반 오른쪽/왼쪽·휴지통 오른쪽/왼쪽의 네 값을 편집한다. 기본값은 일반 오른쪽 완료/해제·왼쪽 삭제, 휴지통 오른쪽 복원·왼쪽 영구 삭제다. 일반 후보는 완료/해제·편집·삭제, 휴지통 후보는 복원·영구 삭제로 제한한다. 저장해야 적용되며 취소/뒤로 가기는 draft를 버린다.
- `TaskSwipeOptions`와 `AppSettings.taskSwipes`를 추가하고 기존 mapper가 `app_settings`의 `taskSwipes` JSON을 읽고 쓴다. 키가 없는 기존 DB나 잘못된 JSON은 기본값, 허용되지 않는 동작은 해당 방향 기본값으로 복원한다. 설정 저장은 최신 AppSettings에 스와이프 값만 합쳐 정렬/필터/숨김/알림 설정을 보존한다. 기존 key/value 저장을 재사용해 schema·migration·repository 메서드 계약은 변경하지 않았다.
- `MobileHomePage._taskRow`에 Dismissible을 연결하고 `_applySwipe`가 기존 callback을 호출한다. 완료/해제는 기존 알림 취소/예약·위젯 갱신, 편집은 기존 상세 Bottom Sheet, 삭제는 기존 휴지통 이동, 복원은 기존 소속·상태 복원 정책을 따른다. 영구 삭제는 기존 확인창을 `_confirmPermanentDelete`로 추출해 row 메뉴와 공유한다.
- 스와이프는 동작 이름/아이콘을 배경에 보여주고, 충분한 거리/속도를 넘긴 경우만 실행한다. confirmDismiss는 항상 false로 끝내며 실제 row 제거/이동은 repository 결과의 재조회로 결정한다. 같은 Task의 동시 스와이프는 ID로 막는다. 실패 시 재조회·오류 안내를 제공해 다시 실행할 수 있다. 설정 저장 중 버튼과 뒤로 가기를 잠그고, 저장 오류는 스크롤과 무관하게 버튼 위에 표시한다.
- Drawer의 화면 전체 감지 영역은 Task 동작보다 먼저 제스처를 잡으므로 기본 가장자리 영역으로 되돌리고 본문 부모에 가로 제스처를 둔다. Task의 자식 Dismissible이 우선하며, 빈 공간/섹션 제목의 오른쪽 드래그는 메뉴를 연다. 가장자리 열기·메뉴의 왼쪽 닫기·세로 스크롤·체크박스·상세 탭은 유지한다. 앞선 UI-008의 ‘Task 행에서도 메뉴 열기’는 이 작업부터 ‘Task 행은 작업, 행 밖은 메뉴’로 변경된다.
- 앱 변경 6개: 신규 `task_swipe_options.dart`, 신규 `task_swipe_settings_sheet.dart`, `settings_repository.dart`, `metadata_mappers.dart`, `main_shell_screen.dart`, `mobile_home_page.dart`. 테스트 3개: `mobile_home_test.dart`, `drift_metadata_repositories_test.dart`, `list_groups_test.dart`. 목록 관리 테스트는 새 설정 구역으로 아래에 내려간 진입 행을 실제 스크롤·레이아웃 완료 뒤 탭하도록 보완했다. 캘린더/관리 화면 row의 스와이프와 휴지통 다중 선택·임시 정렬은 이번 범위에 없다.
- [최종 관련 55건 통과](task-swipe-verified-tests-20261031.jsonl): 홈 30건 + 홈/캘린더/목록 관리 회귀 12건 + 메타데이터/설정 13건. 신규 UI 4건은 모든 기본 동작·영구 삭제 취소/확정·짧은 드래그 무동작·설정한 방향 편집/완료·네 방향 값 저장/재실행·설정 취소·다른 설정 보존·작업/설정 저장 실패와 재시도를 검증한다. 신규 호환 1건과 기존 SQLite 재개방 검증 보강도 포함한다.
- `task-swipe-tests`/`task-swipe-check-tests`는 테스트의 DropdownButtonFormField API 오용, 추가 설정 키 개수, 스크롤 완료 전 탭 문제로 실패한 중간 원본이다. `task-swipe-home-tests`는 설정 오류가 스크롤 아래에 있던 문제를 드러냈고 오류를 고정 영역으로 옮겼다. `task-swipe-final-tests`는 가드 보완 전 55건 통과이며 최종은 위 verified 파일이다. 테스트 조건문의 lint 정리 뒤 [호환 1건 재확인](task-swipe-compat-tests-20261031.jsonl)도 통과했다.
- [최종 분석](task-swipe-final-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건). 초기 `task-swipe-analyze`에는 새 테스트 스타일 info 1건이 추가로 있었고 정리했다. [Android debug 빌드](task-swipe-build-20261031.txt) 성공. [요약·소스/APK 해시](task-swipe-summary-20261031.json). [설정 widget 렌더](task-swipe-swipe-settings.png)는 네 방향을 기본값과 다르게 저장하기 직전의 테스트 화면이다.
- Android 직접 확인: 기본 좌우 완료/해제·삭제 → 휴지통 복원·영구 삭제 취소/확정 → 설정의 네 방향을 바꾸고 저장·재실행 후 실제 실행 → 편집에서 상세 저장/닫기 → 짧은 드래그 무동작 → Task 행과 빈 공간/가장자리의 메뉴 열기 구분 → 세로 스크롤·긴 제목·큰 글씨·알림/위젯 확인. 기기 설치·이번 변경 커밋은 미수행이다.

## 휴지통 선택 작업·임시 보기 — 2026-10-31

- 홈 휴지통의 ‘선택’에서 체크박스·선택 개수·전체 선택/해제·선택 복원·선택 삭제를 제공한다. 행 터치는 선택/해제, 뒤로 가기는 선택 취소로 처리한다. 선택 중에는 row 스와이프와 개별 메뉴를 막는다. 선택 항목이 없으면 작업 버튼이 비활성화된다.
- 작업 대상은 현재 날짜/필터 결과에 보이는 선택 Task의 ID다. 필터/정렬/기간을 바꾸면 선택을 해제하고, 외부 갱신으로 휴지통에서 나간 ID도 제거한다. 전체 선택은 가려진 Task를 포함하지 않는다. 선택 삭제는 개수 확인창을 한 번 거쳐 영구 삭제하며 취소하면 데이터와 선택을 유지한다.
- 기존 `onRestoreTask`/`onDeletePermanently`를 항목별로 호출해 완료 상태·목록 소속·알림·위젯 정책을 재사용한다. 전체를 새 transaction으로 묶지 않는다. 각 항목이 독립적으로 처리되므로 부분 성공이 가능하고, 성공 항목은 선택에서 제거하며 실패 항목은 재조회 결과에 남아 있으면 선택을 유지해 재시도한다. OS 후처리 오류도 있을 수 있어 오류 항목은 재조회한 결과를 확인하도록 안내한다.
- `_trashView`를 홈 `_view`와 분리했다. 기존 5개 정렬·우선순위/태그 필터 UI를 재사용하되 휴지통은 ‘휴지통 보기 (임시)’와 닫기 버튼만 제공하며 저장하지 않는다. 홈의 영구·미저장 보기와 독립적이고, 다른 Drawer 범위/하단 탭 이동·앱 재실행 때 초기화한다. 날짜 선택 정책은 유지한다.
- 변경 파일: `mobile_home_page.dart`(선택/일괄 처리/임시 보기), `main_shell_screen.dart`(홈 활성 여부 전달), `mobile_home_test.dart`(회귀 6건 추가). 기존 영구 삭제 확인창은 단일/일괄에서 공유한다. [직전 스와이프 스냅샷](task-swipe-summary-20261031.json)과 비교해 DB·repository·eCampus·알림 서비스가 변경되지 않았음을 확인한다.
- [관련 화면 42건 통과](trash-bulk-tests-20261031.jsonl): 홈 36건 + 기존 홈/캘린더/위젯 6건. 신규 6건은 선택한 active/completed Task의 원래 목록·상태 복원, 전체 선택/해제, 선택 중 탭/스와이프/뒤로 가기, 영구 삭제 취소/확정·비선택 보존, 임시 정렬의 홈 설정 격리·범위/탭/재실행 초기화, 필터/기간 변경과 보이는 항목만 처리, 복원/삭제 부분 실패·실패 항목 재시도를 검증한다.
- [캡처용 관련 2건 통과](trash-bulk-capture-tests-20261031.jsonl)는 위 테스트 일부의 재실행이다. 선택 복원 테스트는 360px 폭·1.5배 글씨로도 확인했다. widget 렌더: [큰 글씨 선택 모드](trash-bulk-trash-selection.png) · [휴지통 임시 보기](trash-bulk-trash-view.png). [정적 분석](trash-bulk-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건), [Android debug 빌드](trash-bulk-build-20261031.txt) 성공. [요약·소스/APK 해시](trash-bulk-summary-20261031.json).
- Android 직접 확인: 휴지통 → 선택 → 개별/전체 선택·해제 → 선택 복원/영구 삭제 취소·확정 → 완료 Task 복원 후 상태와 목록 보존 → 태그/날짜로 일부를 가리고 전체 선택해 숨겨진 항목 보존 확인 → 임시 정렬 후 홈·캘린더 왕복 시 초기화/홈 설정 유지 → 선택 중 뒤로 가기·세로 스크롤·큰 글씨·알림/위젯 확인. 기기 설치·이번 변경 커밋은 미수행이다.

## 휴지통 실제 필터 후보·행 체크 선택 — 2026-10-31

- 휴지통 보기 조정의 후보를 필터 적용 전 삭제된 Task 전체에서 산출한다. 실제 사용한 우선순위와 태그만 표시하고, 상태는 보존된 completedAt 유무로 삭제 전 미완료/완료 중 실제 있는 값을 표시한다. 휴지통에서는 이 상태로 필터한다. 다른 필터나 현재 날짜 범위 때문에 가려진 휴지통 항목도 후보 계산에는 포함해 선택지가 갑자기 사라지지 않게 한다. 홈의 후보와 저장 설정은 유지한다.
- 휴지통 행의 휴지통 아이콘을 항상 보이는 선택 체크박스로 바꾸고, 별도 체크리스트 아이콘/선택 진입 버튼은 제거했다. 체크하면 선택 모드가 시작된다. 선택 취소·뒤로 가기·처리 완료 후에도 행에는 체크 해제된 선택 상자가 남는다. 일반 모드의 제목 탭은 상세, 선택 모드의 행 탭은 선택/해제를 유지한다.
- 변경은 `mobile_home_page.dart`, `mobile_home_test.dart`다. [직전 스냅샷](trash-bulk-summary-20261031.json)과 비교해 DB·repository·eCampus·알림 서비스가 동일한지 확인한다. 앞선 UI-012의 별도 선택 버튼/휴지통 상태 필터 비활성 설명은 이 보완부터 위 동작으로 바뀐다.
- [홈 UI 38건 통과](trash-filter-tests-20261031.jsonl). 신규 2건은 체크박스 직접 선택·취소, 선택 아이콘 제거, 휴지통 밖에서만 쓰는 우선순위/태그 제외, 실제 상태 필터, 후보 유지, 완료/우선순위/태그가 없는 경우·빈 휴지통을 검증한다. 기존 선택 복원/삭제·실패 재시도·임시 보기·개별 스와이프 회귀도 통과했다. [캡처용 2건](trash-filter-capture-tests-20261031.jsonl)은 신규 테스트 재실행이다.
- widget 렌더: [기본 행 선택 상자](trash-filter-trash-checkboxes.png) · [휴지통 값만 있는 보기 조정](trash-filter-trash-filter-options.png). [분석](trash-filter-analyze-20261031.txt) 오류·경고 0건(기존 info 1건), [APK 빌드](trash-filter-build-20261031.txt) 성공, [요약·소스/APK 해시](trash-filter-summary-20261031.json).
- Android 직접 확인: 휴지통 행의 상자로 선택 시작/취소 → 선택 복원/삭제 → 완료/미완료 항목과 서로 다른 우선순위·태그를 넣고 실제 후보·필터 확인 → 휴지통을 비우면 없는 값이 표시되지 않는지 확인. 기기 설치·이번 변경 커밋은 미수행이다.

## eCampus 가져오기 진입 간소화 — 2026-10-31

- 가져오기 컨트롤러는 유지하고 네 단계 카드·보안 안내 카드로 된 중간 UI를 제거했다. 기존 쿠키를 정리한 뒤 같은 경로 안에 `EcampusLoginWebViewScreen`을 표시한다. 로그인용 추가 Navigator push는 없다. 로그인 후에는 조회 로딩만 표시하고 기존 검토 경로를 연다. 쿠키 정리 중에는 짧은 로그인 준비 표시가 필요하다.
- WebView의 새 `onLoggedIn` callback이 세션을 전달한다. 직접 화면으로 쓰는 기존 호출을 위해 callback이 없으면 pop으로 반환하는 방식도 유지한다. 완료 신호와 시도별 callback은 한 번만 처리하며, 대기가 끝나면 세션 결과를 잡고 있는 callback 참조를 해제한다. 취소/화면 종료 뒤 늦은 완료는 로그아웃·쿠키 정리만 하고 화면이나 조회를 다시 열지 않는다.
- 기존 `_startSync`/`_finishSession`과 flow/apply/알림 연결을 재사용한다. 로그인 취소는 정리 후 복귀하고, 조회 오류는 같은 경로에서 다시 시도할 수 있으며 매 시도 새 로그인을 거친다. 조회 중 취소와 늦은 응답 무시, 반영 성공/실패 뒤 세션 정리도 유지한다. DB·HTML parser·비교·MISSING·반영 transaction·알림 서비스는 변경하지 않았다.
- 변경 앱 파일은 `ecampus_sync_progress_screen.dart`, `ecampus_login_webview_screen.dart`, 테스트는 `ecampus_review_flow_test.dart`, `mobile_home_test.dart`다. 화면 이름의 내부 클래스명은 유지해 기존 연결을 재사용했다. [직전 스냅샷](trash-filter-summary-20261031.json)과 소스 해시를 비교한다. 기존 스냅샷에 없던 WebView 파일은 작업 시작 당시 수정이 없었던 HEAD blob을 추가 기준으로 삼는다.
- [관련 화면 60건 통과](direct-import-verified-tests-20261031.jsonl): eCampus 검토/세션 22건 + 홈 38건. 신규 5건은 로그인 전후 경로 수(기본+가져오기 2개, 검토 후 3개), 중복 완료 무시, 조회 로딩, 로그인 취소, 실패 후 재로그인, 조회 중 취소·늦은 응답 무시, 취소 후 늦은 로그인 결과의 정리를 검증한다. 기존 NEW/CHANGED/MISSING·과목 분류·commit 성공/실패·로그아웃 실패 회귀도 통과했다. callback 참조 해제 뒤 [eCampus 22건 재확인](direct-import-session-release-tests-20261031.jsonl)도 통과했다. 두 실행의 중복 테스트를 합산하지 않는다.
- 테스트는 로그인 UI 대역, Mock HTTP, 실제 Drift 메모리 DB를 사용했다. 실제 학교 계정·Android WebView 성공을 뜻하지 않는다. `direct-import-tests`는 늦은 로그인 보강 전 59건 통과, `direct-import-final-tests`는 테스트 괄호 편집 중 컴파일 실패 원본이다. 최종은 verified 및 session-release 파일이다. [최종 분석](direct-import-final-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건), [최종 APK 빌드](direct-import-final-build-20261031.txt) 성공, [소스/APK 해시·측정 요약](direct-import-summary-20261031.json). 초기 분석/빌드 기록은 보강 전 시점으로 보존한다.
- Android 직접 확인: 홈/설정의 가져오기에서 단계 카드 없이 로그인으로 진입 → 로그인 취소 후 복귀 → 로그인 후 조회/검토/반영 → 다음 가져오기에서 재로그인 → 네트워크 실패 후 재시도 → 조회 중 뒤로 가기 후 늦은 화면 전환 없음 → 기존 알림/위젯 갱신 확인. 기기 설치·실제 계정 로그인·이번 변경 커밋은 미수행이다.

## 기간별 마감 임박·지남 기준 점검 — 2026-10-31

- 앱 동작은 기존 합의와 일치했다. `MobileHomePage.build`의 `periodTasks`(694행)는 선택 기간의 마감일과 마감 없는 미완료 Task를, `completed`(703행)는 선택 기간의 completedAt을 우선 사용한다. 임박/지남(697/702행)은 같은 목록/태그/보기 조건에 맞는 미완료 전체에서 실제 now로 판별하며 선택 기간으로 제한하지 않는다. 따라서 기간 섹션과 보조 섹션의 같은 Task가 겹쳐 보일 수 있다.
- `home_task_summary.dart`의 `isTaskUrgent`(55행)는 오늘 마감을 제외한 D+1~설정한 D+N 날짜 전체를 포함한다. N×24시간 이동 구간이 아니다. `isDueDateOverdue`(75행)는 마감 시각이 now보다 엄격히 이전일 때 참이며 동일 시각은 아직 지남이 아니다. 완료/삭제는 홈의 active 필터에서 제외되고 마감 없는 항목은 임박/지남에 들어가지 않는다. 실행 중 화면 재계산은 MainShell의 `_scheduleClockRefresh`(130행)가 다음 분마다 요청한다.
- 앱 코드는 수정하지 않았다. 변경은 `home_task_summary_test.dart`, `mobile_home_test.dart` 두 테스트 파일과 기록이다. 신규 회귀 5건: 정확한 연말 자정의 임박→오늘→지남 전환/마감 없음/완료·삭제 제외 1건, 연말·윤년·월말의 D+1/D+N 마지막 시각/다음 날 제외 및 0·음수 기준 3건, 오늘/이번 주/이번 달/전체/단일 날짜/구간을 바꿔도 현재 기준과 목록 범위를 유지하고 완료 시각을 우선하는 UI 1건.
- [관련 테스트 46건 통과](date-policy-tests-20261031.jsonl): 마감 요약 7건 + 홈 39건. [정적 분석](date-policy-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건). [소스 비교·결과 요약](date-policy-summary-20261031.json)으로 [직전 가져오기 스냅샷](direct-import-summary-20261031.json) 대비 기록된 앱 코드가 동일함을 확인한다. 이번 작업은 APK를 빌드하지 않았다. 로컬 APK의 관측 해시는 직전 기록과 달라 별도로 기록하며 이번 소스 검증의 근거로 사용하지 않는다.
- 직접 확인: 다른 날짜/구간을 선택해 첫 섹션과 완료만 바뀌고 실제 현재 기준의 임박/지남은 같은 목록 범위에서 유지되는지 확인한다. 임박 N일의 마지막 날 마감과 그 다음 날, 오늘 시간이 지난 마감, 미래 마감 Task를 오늘 완료한 경우의 완료 섹션을 함께 확인하면 된다. 정책을 선택 날짜 기준으로 바꾸는 작업은 하지 않았다.

## 빈 목록 안내 문구 — 2026-10-31

- 홈 공통 빈 섹션은 ‘할 일이 없습니다.’, 전체 일정 관리의 전체 필터는 ‘일정이 없습니다.’로 변경했다. 앱에서 보이는 ‘표시할’ 문구 두 곳만 수정했다. 위젯 서비스의 개발자 주석은 유지한다.
- 변경: `mobile_home_page.dart`, `main_shell_screen.dart`, 기존 `mobile_home_test.dart`의 빈 화면 테스트. [관련 기존 UI 1건 통과](empty-copy-tests-20261031.jsonl)는 실제 화면에서 홈 네 섹션과 설정→전체 일정 관리의 문구를 확인한다. 문구 변경 범위에 맞춰 전체 회귀는 반복하지 않았다.
- [분석](empty-copy-analyze-20261031.txt) 오류·경고 0건(기존 onReorder info 1건), [Android debug 빌드](empty-copy-build-20261031.txt) 성공. [요약·소스/APK 해시](empty-copy-summary-20261031.json)는 [직전 점검 스냅샷](date-policy-summary-20261031.json)과 비교한다. DB·eCampus·CRUD·기간/필터 정책은 동일하다. 기기 설치·이번 변경 커밋은 미수행이다.

## 기간 복원·Drawer 전체 조회 — 2026-10-31

- 기존 설정 key/value 저장소에 `homePeriod`를 추가했다. 오늘/이번 주/이번 달/전체는 종류를 저장해 재실행 시 현재 날짜로 계산하고, 단일 날짜/구간은 고른 날짜를 복원한다. 선택 확정 시 자동 저장하며 취소하면 저장하지 않는다. 손상 값·알 수 없는 종류·역전 구간·존재하지 않는 날짜는 오늘로 복구한다. DB v7 스키마·migration은 변경하지 않았다.
- 최신 AppSettings를 읽고 기간만 합쳐 저장한다. 정렬·필터의 미저장 변경을 함께 저장하지 않고 기존 알림·숨김·스와이프 설정을 보존한다. 저장 중 중복 입력을 막고 실패 시 안내해 다시 선택할 수 있다.
- Drawer 상단은 시계 아이콘의 선택 기간과 기본 문서 아이콘의 전체다. 미지정은 목록 섹션의 루트 목록으로 이동했다. 전체는 날짜 제한 없이 현재 홈의 섹션·Task row·보기 조정·상세/완료/삭제 콜백을 재사용한다. 휴지통·제외 항목은 기존 정책대로 별도 관리하며 상태·우선순위·태그 필터는 적용된다.
- 전체 조회 중 상단 날짜 선택은 비활성화한다. 저장한 기간을 덮어쓰지 않아 시계 메뉴로 돌아오면 원래 기간을 사용한다. 목록/태그/완료/휴지통 범위의 기간 조건, 실제 현재 기준의 임박/지남은 유지한다. Drawer scope 자체는 이번에 영구 저장하지 않는다.
- 설정의 ‘전체 일정 관리’ 진입점과 `_TaskListPage`, 해당 페이지 전용 정렬·필터·재정렬·완료 일괄 삭제 표시 코드를 제거했다. 목록·태그 관리에서도 쓰는 Task/SubTask 표시와 CRUD/알림/위젯 콜백은 유지한다. eCampus 서비스·parser·비교·검토·반영·세션 로직은 변경하지 않았다.
- [관련 테스트 68건 통과](navigation-period-final-tests-20261031.jsonl): 설정 저장소 14건 + 홈 42건 + 캘린더/위젯 6건 + 목록 관리 6건. DB 파일 close/reopen 후 구간 복원, 상대 기간·단일 날짜·양끝 포함 구간의 앱 재시작 복원, 취소/실패 재시도, 미저장 보기 분리, Drawer 순서·아이콘, 전체의 미래/과거 완료 조회와 기간 복귀, 설정 메뉴 제거·기존 상세 진입을 확인했다.
- [첫 실행 원본](navigation-period-tests-20261031.jsonl)은 65건 통과·3건 실패다. 새 설정 행 수와 기간 복원에 대한 옛 기대값, 신규 테스트의 상세 닫기 tooltip을 수정했으며 앱 동작 수정 없이 최종 68건이 통과했다. [캡처용 1건](navigation-period-capture-tests-20261031.jsonl)은 같은 테스트 일부의 재실행이며 합산하지 않는다. widget 렌더: [Drawer 배치·아이콘](navigation-period-drawer-scopes.png) · [전체 조회](navigation-period-all-tasks.png).
- [최종 분석](navigation-period-analyze-20261031.txt), [검증 요약·소스 해시](navigation-period-summary-20261031.json)를 보존한다. 전체 테스트·APK 빌드·실기기 설치는 반복하지 않았다.
- Android 직접 확인: 각 기간 선택 → 앱 완전 종료/재실행해 복원 → Drawer 아이콘·미지정 위치 → 전체에서 미래·이전 완료 조회 → 시계 메뉴에서 원래 기간 복원 → 전체의 상세/완료/보기 조정 → 설정에서 옛 전체 일정 관리 메뉴가 없는지 확인한다.

## Drawer 컨텍스트 메뉴·분류 이동·휴지통 기간 — 2026-10-31

- 일반 기간 선택은 오늘/이번 주/이번 달/기간 선택만 제공한다. 전체 조회는 Drawer의 문서 아이콘을 사용한다. 기존 저장 값이 전체이면 일반 기간은 오늘로 복구한다. 홈 상단의 범위명은 기간/전체 모두 ‘할 일’, 목록은 기존 목록 이름을 사용하며 Drawer에 ‘할 일’ 구역 제목을 추가했다.
- 폴더/목록/태그 길게 누르기는 위치에 붙는 컨텍스트 메뉴다. 목록/태그는 원래 누른 손가락을 움직이면 메뉴가 닫히고 드래그로 이어진다. 메뉴를 모달 route로 띄우지 않아 pointer를 가로채지 않는다. 바깥 탭·Drawer 닫기·항목 폐기 때 메뉴 overlay를 정리한다. 기존 편집/추가 callback을 재사용한다.
- 목록·태그 행의 위/아래에 놓으면 앞/뒤로 배치하며 삽입선만 표시한다. ‘끝으로 이동/폴더 밖으로 이동’ 같은 임시 행은 추가하지 않아 드래그 중 배치가 밀리지 않는다. 목록을 폴더에 놓으면 안으로, 기존 목록 구역 제목이나 미지정 행에 놓으면 폴더 밖으로 이동한다. 가장자리 드래그 스크롤과 대상 강조를 지원한다. 미지정은 드래그 대상에서 제외한다. 목록은 기존 moveList transaction을 재사용하되 beforeListId가 없으면 대상 그룹 끝에 배치하도록 순서 저장을 보완했다. Task의 목록 ID·완료·삭제 이력은 변경하지 않는다.
- 태그 순서는 기존 AppSettings.tagSortOrders에 저장하고 최신 설정과 합쳐 다른 기간·필터·숨김·알림 설정을 보존한다. 실패하면 화면을 낙관적으로 재배치하지 않고 오류 안내 후 재시도한다.
- 설정의 목록·태그 관리 진입점을 제거했다. 기존 내부 관리 State의 생성·편집 handler는 유지해 Drawer에서 호출한다. 보관된 목록은 할 일이 아닌 목록 컨테이너의 보관이다. 목록 구역의 보관 아이콘에서 기존 restoreList로 복원한다. 제외된 eCampus 항목은 휴지통 바로 아래에서 기존 제외 해제 화면을 연다. eCampus 서비스/반영 로직은 변경하지 않는다.
- 휴지통은 들어갈 때마다 전체 기간이 기본이며 같은 메뉴 재선택·다른 범위/하단 탭 왕복에도 초기화한다. 오늘/이번 주/이번 달/전체/직접 기간을 임시로 고를 수 있다. 일반 홈의 저장된 기간과 별도이므로 서로 덮어쓰지 않는다. 휴지통 정렬·필터·선택/복원/영구 삭제는 기존 경로를 유지한다.
- [최종 관련 85건 통과](drawer-context-natural-drop-final-tests-20261031.jsonl): 설정 14건 + DB v7 13건 + 목록 UI 6건 + 홈 46건 + 캘린더/위젯 6건. 목록의 앞/끝 순서와 폴더 안팎 이동, Task 이력 보존·stale target rollback, 태그 저장 실패/재시도와 설정 보존, 재시작 복원, 미지정 보호, 보관 목록 복원, 제외 해제, 기존 상세/완료/가져오기 회귀를 확인했다.
- 같은 휴지통 메뉴 재선택 초기화 보완 뒤 [관련 3건 재확인·캡처](drawer-context-capture-tests-20261031.jsonl), 정적 메뉴 [1건 재확인·캡처](drawer-context-menu-capture-tests-20261031.jsonl)도 통과했다. 이 실행은 85건과 중복되므로 합산하지 않는다. [최종 분석](drawer-context-analyze-20261031.txt) 문제 없음, [결과·소스 해시](drawer-context-summary-20261031.json). 전체 테스트·APK 빌드·실기기 설치는 수행하지 않았다.
- 중간 원본도 유지한다. first-tests는 보강 전 75건 통과, new-tests는 테스트 helper 선언 순서에 따른 컴파일 실패, new-verified-tests는 기존 태그 순서 기대값 정정 전 3건 통과/1건 실패, final-tests는 기대값 비교 변수 선언 누락으로 로드 실패한 실행이다. 추가 이동 행을 없앤 뒤 natural-drop-tests는 Flutter의 ListTile ink 가림 진단 2건을 감지했다. 대상 표시는 Material/Ink로 수정해 선택 배경과 삽입선을 같은 Material에 그린다. 최종 결과는 natural-drop-final-tests를 기준으로 하며 앞선 final-verified 85건과 캡처 실행은 시점 기록이다.
- widget 렌더: [Drawer 구역·제외 항목](drawer-context-drawer-scopes.png) · [목록 컨텍스트 메뉴](drawer-context-list-actions.png) · [휴지통 전체 기간](drawer-context-trash-all-dates.png). 드래그 중 메뉴 캡처에는 실패 주입 후 오류 안내가 남아 있는 장면도 포함되며 실제 계정·기기 화면이 아니다.
- Android 직접 확인: 폴더/목록/태그 정지 long press와 누른 채 이동 구분 → 메뉴 닫힘·순서 저장·폴더 안팎 이동 → 스크롤 끝 이동 → 미지정 이동 불가 → 재실행 순서 복원 → 보관 목록 복원 → 휴지통 기본 전체/임시 기간/재진입 초기화 → 제외 항목 해제 → 홈 기간 보존을 확인한다.

최종 사용성 보완: 드래그 중 생기던 이동 안내 행을 제거한 뒤 동일 관련 **85건 재확인 통과**, 분석 문제 없음. 보관된 목록은 목록 컨테이너의 보관/복원이며 삭제된 Task의 휴지통과 별개다.

## 숨김 컨텍스트 메뉴 단순화·보관 기능 제거 — 2026-10-31

- 사용자 요청으로 목록 보관 버튼·복원 메뉴·전용 처리와 GroupedListRepository의 getArchivedLists/restoreList를 제거했다. 숨김만 사용자 기능으로 남긴다. 사용자가 전환도 필요 없다고 정정해 기존 보관 데이터의 복원/숨김 전환은 구현하지 않았다. DriftSettingsRepository는 이번 변경 전과 동일하며 DB 스키마·migration·기존 행은 그대로다.
- 목록/태그 제목 오른쪽의 숨김 아이콘은 서로 다른 컨텍스트 메뉴를 연다. Bottom Sheet가 아니다. 각 메뉴에는 해당 이름과 눈 아이콘만 표시하며 미지정·폴더 경로·그룹 제목·표시/숨김 상태 문구·설명·스위치·닫기 버튼을 넣지 않는다. 미지정은 이 팝업에서만 제외하며 기존 Drawer 기본 목록은 유지한다.
- 팝업 폭은 실제 이름 글자 폭과 시스템 글자 배율을 계산해 152~208로 제한한다. 본문 글자 14, 좌우 여백 12, 눈 아이콘 오른쪽 정렬과 세로 중앙 정렬을 고정했다. 긴 이름은 한 줄 말줄임, 항목이 많으면 팝업 안에서 스크롤한다. 기존 테마 색상을 사용한다.
- 눈을 누르면 최신 AppSettings에 해당 ID 변경만 합쳐 즉시 저장한다. 선택한 Task 범위·Task 목록 소속·기간·정렬·태그 순서·알림 등은 보존한다. 저장 중 중복 입력을 막고 실패하면 기존 눈 상태를 유지하며 재시도한다. 팝업 밖 터치/뒤로 가기로 닫는다.
- [관련 87건 통과](visibility-menu-final-tests-20261031.jsonl): 설정 15건 + DB v7 13건 + 목록 UI 6건 + 홈 47건 + 캘린더/위젯 6건. 보관 API 제거 후 관계·이관·가져오기·목록 드래그 회귀, 설정 읽기 시 기존 삭제/보관 행을 전환하지 않는지, 숨김 저장/재실행·완료 Task 소속 보존·목록/태그 분리·미지정 제외·실패 재시도를 검증했다.
- 폭과 정렬을 마지막으로 정리한 뒤 [해당 UI 2건 재확인·캡처](visibility-menu-layout-final-tests-20261031.jsonl)도 통과했다. 폭 범위·텍스트/눈 위치와 정렬을 함께 확인했다. 앞의 87건과 중복이므로 합산하지 않는다. [최종 분석](visibility-menu-analyze-20261031.txt) 문제 없음, [요약·소스 해시](visibility-menu-summary-20261031.json). widget 렌더: [목록 숨김](visibility-menu-list-visibility.png) · [태그 숨김](visibility-menu-tag-visibility.png).
- 중간 원본은 보존한다. first-tests는 PopupMenu의 intrinsic layout과 ListView 충돌을 감지한 실행이며 고정 폭·SingleChildScrollView/Column으로 해결했다. new-verified는 관련 4건 통과, final-capture는 초기 여백 보완 후 2건 통과, layout-tests는 ListTile에서 간단한 Row로 변경한 뒤 테스트의 옛 캐스트를 갱신하기 전 실행이다. 최종은 final-tests와 layout-final-tests다.
- Android 직접 확인: 목록/태그별 눈 메뉴 → 각 대상만 나오고 미지정/경로/문구가 없는지 → 눈 활성/비활성 즉시 변경 → 메뉴 밖/뒤로 닫기 → 재실행 후 숨김 유지 → 긴 이름·큰 글씨·많은 항목의 폭/스크롤 → Task 소속과 완료·휴지통 상태 보존 → 보관/복원 메뉴 없음 확인. 실제 설치·APK 빌드·전체 테스트·커밋·push는 수행하지 않았다.

## 설정 컨텍스트 메뉴·즉시 저장 — 2026-10-31

- UI-020. 별도 설정 페이지와 미사용 `settings/settings_screen.dart`를 제거했다. Drawer 설정을 누르면 스와이프·알림 토글 아이콘·알림 시점(알림 켜짐일 때만)·마감 임박의 컨텍스트 메뉴를 연다. Drawer의 기존 기능·색상 테마와 SettingsRepository를 재사용한다.
- 스와이프 하단창은 중앙 제목과 할 일/휴지통 두 구역, 각 오른쪽/왼쪽 선택만 제공한다. 변경 즉시 해당 방향만 최신 설정에 병합해 저장한다. 저장·취소·설명은 제거하고 큰 글씨의 긴 선택값도 전부 보이게 했다.
- 알림 시점·마감 임박은 작은 슬라이더 하단창이다. 움직이는 중에는 표시만 바꾸고 손을 놓으면 저장한다. 기존 알림 후보(마감 시각~3일 전), 임박 1~14일 범위를 유지한다. 저장 실패는 이전 값으로 돌아가고 같은 컨트롤에서 재시도한다. 기간·보기·숨김 설정을 함께 덮어쓰지 않는다.
- 알림 토글은 기존 `defaultNotificationEnabled` 의미(새 Task의 기본값)를 유지한다. 켤 때 기존 권한 요청을 호출하며 기존 일정의 예약을 일괄 취소/재예약하는 전역 기능은 추가하지 않았다.
- 설정 전용 eCampus 가져오기/로그인/세션/마지막 가져오기/수동 쿠키 정리 UI와 보조 handler만 제거했다. 실제 가져오기 컨트롤러·로그인·auth/cookie 서비스는 변경하지 않았고 가져오기 종료/취소/실패 정리는 그대로다. DB·migration·repository 계약도 변경하지 않았다.
- 변경 코드: `main_shell_screen.dart`, `mobile_home_page.dart`, `task_swipe_settings_sheet.dart`, 신규 `home_settings_menu.dart`, 삭제 `settings/settings_screen.dart`; 기존 UI 테스트 2개 파일 갱신.
- [최종 관련 83건 통과](settings-popup-final-tests-20261031.jsonl): 홈 49 + 홈/캘린더/위젯 6 + 목록 6 + eCampus 22. 마지막 부모 callback의 mounted 보호 뒤 [UI 3건/캡처](settings-popup-capture-tests-20261031.jsonl)와 [shell 6건](settings-popup-shell-final-tests-20261031.jsonl) 재확인도 통과했다. 중복 검증이므로 합산하지 않는다. [분석](settings-popup-analyze-20261031.txt) 문제 없음. [요약·소스 해시](settings-popup-summary-20261031.json).
- 중간 실패 원본(first/new-verified/controls)은 보존한다. 중복 라벨 finder, 오류 안내 위치/누적, 오류 문구로 높이가 바뀐 뒤 테스트가 옛 slider 좌표를 사용하던 문제를 수정했다. 통과 여부는 final/capture/shell 로그를 기준으로 한다.
- widget 렌더: [메뉴](settings-popup-settings-menu.png) · [큰 글씨 메뉴](settings-popup-settings-large-menu.png) · [스와이프](settings-popup-swipe-settings.png) · [큰 글씨 스와이프](settings-popup-swipe-large.png) · [알림 시점](settings-popup-notification-time.png) · [마감 임박](settings-popup-urgent-days.png). 실제 Android 캡처가 아니며 eCampus 테스트도 모의 로그인/응답이다.
- Android 직접 확인: 설정 탭이 화면 전환 없이 메뉴 열기 → 알림 켬/끔과 알림 시점 항목 표시 → 네 방향 변경 후 저장 버튼 없이 실제 Task/휴지통 스와이프 → 슬라이더 놓기/닫기/재실행 후 값 유지 → 기존 기간·보기·숨김 유지 → 큰 글씨/작은 화면 → 홈 가져오기 후 재로그인/취소/세션 정리 확인. 전체 테스트·APK 빌드·실기기 설치·커밋·push는 하지 않았다.

## 제외된 eCampus 항목 홈 레이아웃 통일 — 2026-10-31

- UI-021. Drawer의 제외된 eCampus 항목을 별도 route 대신 홈 scope로 선택한다. 완료/휴지통과 같은 상단·하단 navigation·선택 강조·작은 섹션 제목·공통 Task row를 재사용한다. 이전 전용 페이지·카드·안내 문구·상태 chip·텍스트 버튼은 삭제했다.
- 원본 제목은 같은 크기와 줄바꿈 규칙으로 표시하고 마감/과목을 보여준다. 아직 Task로 가져오지 않은 원본이므로 미지정 목록으로 잘못 표시하지 않으며 완료/편집/Task 스와이프도 연결하지 않는다. 행 앞의 다시 가져오기 허용 아이콘만 기존 `_allowExcludedTaskSync`를 호출한다.
- 전체 기간에서 제외 원본만 보여준다. 일반 홈의 날짜/상태/우선순위/태그 때문에 가려지지 않는다. 보기 조정은 기존 정렬 5개를 재사용하고 이 범위를 벗어나면 초기화한다. 일반 홈의 저장 기간/보기는 변경하지 않는다. 설명 문구는 추가하지 않았다.
- 제외 해제 의미는 기존 그대로다. source row를 없애거나 Task를 즉시 복원하지 않고 `ignored → unreviewed`, `taskId=null`을 유지해 다음 가져오기에서 검토할 수 있게 한다. 처리 중 중복 클릭을 막고 실패 시 항목을 유지해 재시도한다. DB/repository/import service/session/notification 로직은 변경하지 않았다.
- 앱 코드 2개(`main_shell_screen.dart`, `mobile_home_page.dart`)와 홈 테스트 1개를 변경했다. [관련 85건 통과](excluded-home-final-tests-20261031.jsonl): 홈 51 + shell/캘린더/위젯 6 + 목록 6 + eCampus 22. 마지막 행 레이아웃 보완 뒤 [영향 UI 3건 재확인·캡처](excluded-home-capture-tests-20261031.jsonl)도 통과했다. 중복이므로 합산하지 않는다. [분석](excluded-home-analyze-20261031.txt) 문제 없음. [요약·소스 해시](excluded-home-summary-20261031.json).
- [첫 실행 원본](excluded-home-first-tests-20261031.jsonl)은 새 테스트가 기존 정책을 source 삭제로 잘못 가정해 2건 통과/1건 실패한 결과다. 실제 repository의 unreviewed 보존을 확인해 기대값만 수정했다. 최종 정렬 검증은 원본 sourceDueDate를 넣어 빠른 순/늦은 순 양쪽 순서 변화를 확인했다.
- widget 렌더: [일반 목록](excluded-home-excluded-list.png) · [빈 목록](excluded-home-excluded-empty.png) · [정렬](excluded-home-excluded-sort.png) · [큰 글씨·긴 제목·과목·마감](excluded-home-excluded-large.png). 실제 Android 캡처가 아니다.
- Android 확인: Drawer 항목 선택 후 같은 홈과 하단바 유지 → 기존 안내/카드 없음 → 기간/홈 필터와 무관하게 제외 원본 표시 → 정렬 변경/이탈 후 초기화 → 제외 해제 아이콘/중복 탭 → 다음 가져오기에서 다시 검토 → 완료·휴지통/일반 Task 동작 유지. 전체 테스트·APK 빌드·설치·커밋·push는 하지 않았다.

## 휴지통·제외 항목 체크 선택 상단 통일 — 2026-10-31

- UI-022. 휴지통/제외된 eCampus 모두 왼쪽 체크박스와 행 전체 터치로 선택한다. 휴지통 행의 상세/편집 진입·개별 popup과 제외 항목의 개별 실행 아이콘을 제거했다. 일반 Task의 상세·완료와 선택 전 휴지통 복원/삭제 스와이프는 유지한다.
- 선택 중에는 기존 상단과 섹션 제목/개수 줄 대신 고정 AppBar를 표시한다. `← N [복원] [삭제]`(휴지통), `← N [체크]`(제외 항목) 아래 왼쪽 체크박스와 모두 선택/모두 해제만 둔다. 개수는 뒤로가기 옆, 모두 선택 체크박스는 행의 체크박스와 같은 x좌표다. 선택 취소/N개 선택/전체 선택/선택 복원/선택 삭제 문구를 제거했다.
- 상단 뒤로가기·Android 이전키는 선택만 해제하고 기존 목록/도구로 돌아간다. 스크롤해도 선택 상단과 모두 선택 줄은 고정된다. 0개 선택에서는 작업 아이콘이 비활성화되며 범위/탭 변경 때 선택을 정리한다.
- 휴지통은 기존 복원·영구 삭제 확인/알림/위젯 경로, 제외는 기존 제외 해제 경로를 재사용한다. 제외 항목의 체크 아이콘은 tooltip 복원이며, 원본 `ignored → unreviewed`로 다음 가져오기 검토를 허용한다. 원본 영구 삭제나 즉시 Task 생성으로 바꾸지 않았다.
- 모두 선택은 화면 밖을 포함한 현재 날짜/필터 결과만 대상으로 한다. 처리 중 중복 실행/선택/뒤로가기를 막는다. 기존 항목별 처리 방식으로 부분 성공이 가능하고 성공한 선택은 제거, 실패한 선택은 유지하여 재시도한다. DB·repository·eCampus/세션 서비스·알림 코드는 변경하지 않았다.
- 앱 코드 `mobile_home_page.dart`와 기존 홈 테스트만 수정했다. [관련 88건 통과](archive-selection-final-tests-20261031.jsonl): 홈 54 + shell/캘린더/위젯 6 + 목록 6 + eCampus 22. 마지막 상단 정렬 보완 뒤 [영향 UI 2건 재확인·캡처](archive-selection-capture-tests-20261031.jsonl)도 통과했다. 중복이므로 합산하지 않는다. [분석](archive-selection-analyze-20261031.txt) 문제 없음. [요약·소스 해시](archive-selection-summary-20261031.json).
- 중간 원본: first는 기존 관련 14건 통과, controls는 신규 3건 통과지만 스크롤 후 시험 탭이 가려진 행을 놓치는 경고가 있었다. 실제 스크롤을 초기화하고 hitTestable/선택 재진입을 확인하도록 보강했다. 최종 로그에는 해당 경고가 없다.
- widget 렌더: 휴지통 [선택](archive-selection-trash-selection-header.png) · [모두 해제](archive-selection-trash-selection-all.png) · [스크롤](archive-selection-trash-selection-scrolled.png), 제외 항목 [선택](archive-selection-excluded-selection-header.png) · [모두 해제](archive-selection-excluded-selection-all.png) · [스크롤](archive-selection-excluded-selection-scrolled.png). 큰 글씨 1.5배의 모의 데이터이며 실제 기기 캡처는 아니다.
- Android 확인: 행/체크박스 각각 선택 → 상단 N·아이콘·모두 선택/해제 → 스크롤 중 고정 → 화살표/이전키로 선택 취소 → 휴지통 복원/삭제 취소·확정 → 제외 항목 복원 후 다음 가져오기 검토 → 기존 일반 할 일 상세와 완료 유지. 전체 테스트·APK 빌드·설치·커밋·push는 하지 않았다.

- UI-022 최종 시각 보완: 제외 항목 작업 아이콘을 체크로 변경했다. 양쪽 공통 선택 상단의 모두 선택 줄은 56→48, 본문 위 여백은 12→0으로 줄였고 숫자/라벨 크기도 기존 홈에 맞췄다. 전체 선택 상단은 두 범위 모두 104이며 체크 터치 영역 48은 유지한다.
- [최종 영향 UI 4건 통과·캡처](archive-selection-height-final-tests-20261031.jsonl): 휴지통/제외 × 기본/큰 글씨. 아이콘, 상단/체크 줄 높이, 행 시작 위치가 더 내려가지 않음, 체크 정렬·선택/해제·스크롤 고정·이전키를 확인했다. 큰 글씨에서는 기존 긴 섹션 제목이 사라져 본문이 위로 이동할 수 있다. 이전 88건과 중복이며 이번 시각 수정 뒤 전체 관련 테스트는 반복하지 않았다. [분석](archive-selection-height-analyze-20261031.txt) 문제 없음, [최종 소스 해시·측정](archive-selection-height-summary-20261031.json). 기존 archive-selection-summary/capture는 보완 전 스냅샷이다.
- 최종 화면: [휴지통](archive-selection-height-trash-selection-header.png) · [제외 체크](archive-selection-height-excluded-selection-header.png) · [큰 글씨 휴지통](archive-selection-height-trash-large-selection-header.png) · [큰 글씨 제외](archive-selection-height-excluded-large-selection-header.png). height-tests 원본은 큰 글씨의 의도된 위쪽 이동까지 절댓값으로 제한해 2건 통과/2건 실패한 중간 실행이고, 최종은 height-final-tests다. 실제 기기 설치·커밋·push는 하지 않았다.

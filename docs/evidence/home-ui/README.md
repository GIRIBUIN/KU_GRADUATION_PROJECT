# 모바일 홈 UI 개편 — 2026-10-30

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

날짜 변경 자동 갱신 수정 — 2026-11-13

1. 수정 내용

기존 Android Provider는 저장된 JSON을 다시 표시하므로 앱을 열지 않으면 날짜 범위가 바뀌지 않았다. 다음 자정 알람 → BroadcastReceiver → JobScheduler → 화면 없는 Flutter 엔진 → 기존 WidgetUpdateService.refresh() 호출 경로를 추가했다. DB에서 오늘/이번 주 전체 목록을 다시 읽고 두 위젯의 설치된 모든 인스턴스를 갱신한다. 페이지 크기, 완료 토글, 등록 폼과 기존 조회·정렬 정책은 유지한다.

- 첫 위젯 업데이트 시 자정 예약 및 현재 날짜 데이터 갱신 요청.
- 재부팅, 패키지 업데이트, 날짜·시각·시간대 변경 시 재예약 및 강제 재조회.
- 날짜 키에 시간대를 포함하고 같은 날짜의 일반 갱신 요청은 중복 실행하지 않는다.
- Calendar로 다음 날짜의 00:00을 계산하여 DST의 23/25시간 날짜도 처리한다.
- 실패·60초 타임아웃·OS 작업 중단은 JobScheduler로 재시도하고 Flutter DB/엔진을 해제한다.
- 위젯이 없으면 알람과 작업을 취소한다. 두 종류 중 하나만 설치되어도 동작한다.
- 전용 Dart 진입점은 vm:entry-point로 유지하며 Activity/runApp을 실행하지 않는다.

2. 변경 파일

- android/app/src/main/AndroidManifest.xml
- android/app/src/main/kotlin/com/example/ku_task_management/WidgetDateRefresh.kt
- android/app/src/main/kotlin/com/example/ku_task_management/WidgetDateRefreshJobService.kt
- android/app/src/main/kotlin/com/example/ku_task_management/ScheduleWidgetProvider.kt
- android/app/src/main/kotlin/com/example/ku_task_management/WeeklyScheduleWidgetProvider.kt
- lib/main.dart
- lib/data/services/widget_background_refresh.dart
- android/app/src/test/kotlin/com/example/ku_task_management/WidgetDateRefreshTest.kt
- test/data/services/widget_background_refresh_test.dart
- docs/testing/widget_date_refresh_2026-11-13.md

기존 android_widget_integration_report_2026-11-13.md의 사용자 체크/메모는 수정하지 않았다. 해당 보고서의 날짜 자동 재조회 미구현 설명은 이 수정 전 상태이다.

3. 최종 검증

- flutter analyze: No issues found.
- flutter test: 147개 통과. 신규 2개는 오래된 JSON에서 일요일/월요일 각각의 DB 범위로 양쪽 스냅샷을 교체하는 백그라운드 서비스 테스트이다.
- :app:testDebugUnitTest: 13개 통과(기존 9 + 신규 4). 실패/오류/skip 0.
- 신규 Android 테스트: 주/연말·DST 자정 계산, 주간만 설치된 경우 알람·작업 예약, 중복 제거, 같은 날짜 작업 생략, 부팅·시간대·시간 변경 강제 요청, 위젯 없음/미지원 이벤트 무시.
- :app:assembleDebug 성공.
- git diff --check 통과.

4. 실기기 확인

연결된 API 33 기기에 최종 APK를 adb install -r로 업데이트 설치했다. 앱 데이터를 지우거나 테스트 일정을 추가하지 않았다. 설치 이후 메인 앱 화면을 실행하지 않았다.

- 패키지 교체 이벤트로 WidgetDateRefreshJobService 자동 실행.
- 로그: Background refresh finished: success=true date=Asia/Seoul:2026:317.
- JobScheduler: 작업 41072가 app called jobFinished로 정상 종료됨.
- AlarmManager: WIDGET_MIDNIGHT가 2026-11-14 00:00:00 Asia/Seoul 기준으로 예약됨.

이 확인은 실제 엔진/플러그인/DB/두 Provider 갱신 경로 및 알람 등록 확인이다. 기기 시간을 변경하거나 실제 자정까지 기다린 시험은 수행하지 않았다. 화면상의 행 렌더링도 이번 확인에는 포함하지 않았다.

5. 실행 시점과 남은 검증

정확한 알람 권한을 새로 요구하지 않도록 setAndAllowWhileIdle을 사용한다. Android 12 이상에서는 일반 상태에서도 자정 이후 약 1시간 범위로 실행될 수 있고 Doze/절전/제조사 제한에서는 더 늦을 수 있다. 따라서 자정 정각 실행을 보장하지 않는다. JobScheduler의 실행 시점도 시스템 정책에 따른다. 설정에서 앱을 강제 중지한 경우에는 다시 앱을 열기 전 자동 실행이 제한될 수 있다.

- [ ] 앱 화면을 열지 않은 채 실제 자정을 넘어 오늘 목록과 날짜 머리글이 바뀌는지 확인.
- [ ] 일요일→월요일에 주간 범위·진행률·페이지 보정 확인.
- [ ] 화면을 끈 Doze/절전 상태에서 지연 시간 기록.
- [ ] 실제 기기 재부팅 후 자정 알람 복구 및 DB 재조회 확인.
- [ ] 시간대/수동 시간 변경 후 범위와 다음 자정 예약 확인.
- [ ] API 34/35 이상 및 제조사 배터리 제한 환경 반복 확인.
- [ ] 마지막 위젯 제거 시 알람/작업 취소 확인.

참고: https://developer.android.com/develop/background-work/services/alarms

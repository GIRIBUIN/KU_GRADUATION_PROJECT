자연 자정 갱신 지연 수정 — 2026-11-14

1. 원인

수동 시간 변경은 TIME_SET 리시버가 강제 갱신을 요청하지만, 자연 자정은 기존 setAndAllowWhileIdle 일반 알람에 의존했다. 수집한 실기기 AlarmManager 기록에서 WIDGET_MIDNIGHT의 일반 알람(window>0)이 battery_saver 정책으로 목표 시각 이후로 지연되어 있었다. 일반 JobScheduler 작업도 Doze/절전 상태에서 대기할 수 있었다. 이전 수정은 화면 없는 DB 재조회 경로를 만들었지만 자정 부근 실행 보장에는 부족했다.

2. 수정

- 정확 알람 접근이 허용된 API 31 이상 및 API 30 이하에서 setExactAndAllowWhileIdle로 다음 자정 예약.
- 권한이 없거나 예약 도중 취소되면 SecurityException으로 중단하지 않고 기존 일반 알람으로 대체하고 경고 로그 기록.
- 정확 알람 권한 허용 이벤트를 받으면 정확 알람으로 다시 예약하고 즉시 데이터 갱신 요청.
- API 31 이상에서는 expedited Job으로 DB 재조회 요청. 우선 작업 할당량 부족으로 RESULT_FAILURE가 반환되면 일반 Job으로 대체하여 요청 유실 방지.
- 기존 DB·일정 범위·정렬·페이지·등록·완료 토글 로직 유지.

변경 파일:

- android/app/src/main/kotlin/com/example/ku_task_management/WidgetDateRefresh.kt
- android/app/src/main/AndroidManifest.xml
- android/app/src/test/kotlin/com/example/ku_task_management/WidgetDateRefreshTest.kt
- docs/testing/widget_natural_midnight_fix_2026-11-14.md

3. 검증 결과

- Android JVM/Robolectric 테스트 17개 통과(기존 13개 + 신규 4개).
- 정확 알람의 window=0 및 idle 허용 검증.
- TIME_SET/DATE_CHANGED를 보내지 않고 예약된 자정 PendingIntent 자체를 전달하여 갱신 Job 요청과 다음 자정 재예약 검증. 이는 알람 전달 경로 시험이며 실제 wall clock으로 밤을 넘긴 시험은 아니다.
- API 31에서 정확 알람 허용 시 우선 Job, 권한 거부 시 일반 알람 대체, 권한 허용 이벤트 후 정확 알람 재등록 검증.
- 우선 Job 할당량 부족 시 일반 Job 대체 검증.
- Flutter 전체 테스트 147개 통과.
- flutter analyze: No issues found.
- :app:assembleDebug 성공. git diff --check 통과.

초기 신규 테스트의 가상 시간 전진으로 java.lang.System의 실제 wall clock도 변경된다고 가정하여 1개 실패했다. 해당 가정을 제거하고 실제 PendingIntent 전달 경로를 시험하도록 수정한 뒤 전체 통과했다. 최종 실패 테스트는 없다.

4. 실기기 검증

연결된 API 33 기기에 adb install -r로 수정 APK를 업데이트 설치했다. 앱 데이터 삭제, 기기 시간 변경, 절전 설정 변경, 권한 강제 부여는 하지 않았다.

- AlarmManager: WIDGET_MIDNIGHT의 다음 자정 예약이 window=0, exactAllowReason=permission, flags=0x5로 등록됨.
- JobScheduler: 작업 41072가 Priority MAX, started as EJ=true로 실행되고 jobFinished로 정상 종료됨.
- WidgetDateRefresh 로그: Background refresh finished: success=true.

설치 이후 경로의 실기기 확인이며 실제 다음 자정까지 기다린 결과는 아니다. 기기 시계는 사용자 수동 설정 상태이므로 로그의 달력 날짜를 호스트 검증 날짜로 사용하지 않았다.

5. 제한 및 기기 확인 절차

- API 31 이상에서 정확 알람 권한이 거부되면 정확한 자정 실행은 보장할 수 없다. 시스템 설정의 앱별 '알람 및 리마인더' 허용이 필요하다. 이 앱은 기존 알림 권한 요청 흐름에서 정확 알람 접근도 요청하고 있으며 이번 수정으로 임의의 권한 팝업을 추가하지 않았다.
- 정확 알람 후 Flutter 엔진 시작·DB 조회·RemoteViews 반영에 수 초가 소요될 수 있다. 제조사 절전 정책, 우선 작업 할당량, 앱 강제 중지에도 영향을 받으므로 모든 환경의 00:00:00 즉시 반영을 보장하지 않는다.
- [ ] 23:58~23:59로 설정한 다음 앱을 열지 않고 자연스럽게 00:00을 넘긴다. TIME_SET 직후의 성공과 자연 자정 성공을 구별하여 기록한다.
- [ ] 자정 이후 오늘 날짜 머리글·오늘 일정·주간 D-day를 확인한다. 일요일→월요일에는 주간 범위·진행률도 확인한다.
- [ ] 화면 켜짐/꺼짐/절전 모드 각각에서 알람 전달, 우선 Job 시작, success=true 시각을 기록한다.
- [ ] 정확 알람 권한 거부 시 일반 알람 대체 및 권한 허용 후 정확 예약 복구를 실기기에서 확인한다.
- [ ] 재부팅 후 다음 자정 정확 예약을 확인한다.

공식 문서:

- https://developer.android.com/develop/background-work/services/alarms
- https://developer.android.com/reference/android/app/job/JobInfo.Builder#setExpedited(boolean)

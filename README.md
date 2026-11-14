# KUTODO

eCampus에서 가져온 학업 할 일과 개인 할 일을 함께 관리하는 Flutter 앱.
건국대학교 컴퓨터공학부 졸업프로젝트이며 팀원은 이의빈, 이유환, 최정길이다.

현재 기준: **2026-11-15 · main · Drift DB v7**. 과거 계획과 현재 구현은 [문서 안내](docs/README.md)에서 구분한다.

## 현재 구현

| 영역 | 동작 |
| --- | --- |
| 할 일 | 생성·수정·완료·휴지통·복원·영구 삭제, 메모·우선순위·알림 |
| 분류 | 폴더 → 목록 → 할 일. 할 일은 목록 하나에 필수 소속되고 태그는 별도로 복수 연결 |
| 미지정 | 직접 만든 할 일의 기본 목록. Drawer의 목록 구역 맨 위에 고정 |
| 홈 | Drawer 범위 + 날짜/기간 + 정렬/필터. 마지막 조회 기간 저장 |
| 공통 목록 | 우선순위 배경, D-N/D+N/D-day와 시간, 서브 작업 펼치기·체크, 길게 눌러 상세 |
| 캘린더 | 월/주 보기, 선택 날짜의 할 일, 기존 생성·상세·완료 연결 |
| eCampus 가져오기 | WebView 로그인 → HTML 조회·파싱 → 비교·검토 → 선택 반영 → 세션 정리 |
| Android 위젯 | 오늘/이번 주, 페이지 이동, 완료·해제, 소속 목록 표시, 목록 선택 빠른 추가, 자정 갱신 |

eCampus 가져오기는 **사용자가 실행하는 읽기 전용 가져오기**다. 서버의 과제·제출 상태를 수정하지 않는다.
로그인 정보를 앱 설정/DB에 저장하거나 로그인 세션을 장기 보관하는 기능은 제공하지 않는다.
현재 결과 검토는 별도 미리보기 화면이며, 결과 Bottom Sheet 개편은 아직 구현하지 않았다.

## 실행

```powershell
flutter pub get
flutter devices
flutter run -d <device-id>
```

Android APK: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`.
연결 기기에 기존 데이터를 지우지 않고 설치: `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`.
환경·위젯 등록·검증 명령은 [실행 및 개발 안내](docs/실행%20및%20개발%20안내.md)를 참고한다.

## 기술과 지원 범위

Flutter/Dart, Drift/SQLite, `flutter_inappwebview`, `http`/`html`, `flutter_local_notifications`, `home_widget`를 사용한다.
화면 상태는 현재 `StatefulWidget`·`FutureBuilder`와 Repository/Service 연결로 관리한다.

- 실제 설치·실행 및 테스트 기록이 있는 기준 기기: **Android / Galaxy S24**.
- 지원 우선 목표: Android·iOS, 이후 웹. iOS 실행·배포와 웹의 인증/플러그인 호환 검증은 남아 있다.
- 현재 네이티브 홈 위젯은 Android 구현이다. 과거 iOS 실험 이력은 보관 태그에 있다.
- 기기 간 동기화, OCR 가져오기, 장기 로그인·주기적 eCampus 조회는 현재 기능에 포함하지 않는다.
- 학교의 외부 연동 허용 범위와 배포 여부는 확정된 것으로 취급하지 않는다. [보안 정책](docs/보안%20정책.md) 참고.

## 문서와 기록

| 목적 | 문서 |
| --- | --- |
| 문서 전체 안내·용어 | [docs/README.md](docs/README.md) |
| 현재 기능·화면 | [기능 설계](docs/기능%20설계.md), [화면 흐름](docs/화면%20흐름.md) |
| DB 구조 | [데이터 모델](docs/데이터%20모델.md), [DB v7 관계도](docs/diagrams/db-v7.md), [DBML](docs/database.dbml) |
| 실제 가져오기 흐름 | [eCampus 연동 구조 분석](docs/이캠퍼스%20연동%20구조%20분석.md) |
| 측정·검증과 개선 과정 | [검증 및 측정](docs/검증%20및%20측정.md), [개선 작업 기록](docs/개선%20작업%20기록.md) |
| 1학기 계획서·2학기 미팅 | [학기별 자료](docs/materials/README.md) |
| 남은 일 | [다음 작업](docs/다음%20작업.md) |

프로젝트명은 문서에서 **KUTODO**, 학교 시스템은 **eCampus**로 표기한다.
학기별 원본 자료에는 당시 제목과 계획이 그대로 남아 있다.

## 개발 구조

```text
lib/app.dart                       앱 초기화·실제 저장소/알림/위젯 연결
lib/data/local/                    DB v7·이관·Mapper
lib/data/repositories/             저장소 계약과 Drift 구현
lib/data/services/                 파싱·비교·반영·조회/위젯 처리
lib/presentation/screens/main/     홈·Drawer·캘린더 연결·설정 메뉴
lib/presentation/screens/sync/     로그인 진입·가져오기 검토
lib/presentation/widgets/          공통 할 일 행·캘린더
android/app/src/main/kotlin/       Android 위젯·백그라운드 갱신
```

최신 개발 브랜치는 main 하나다. 정리한 브랜치의 이력과 복구 위치는 [main 통합 기록](docs/history/main%20통합%20및%20브랜치%20정리%202026-11-15.md)에 있다.

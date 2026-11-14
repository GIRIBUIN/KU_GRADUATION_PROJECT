# Flutter 소스 안내

현재 기준: 2026-11-15.

실제 진입점은 main.dart와 app.dart다. app.dart가 Drift 저장소·알림·위젯을 구성하고 presentation/screens/main/main_shell_screen.dart가 화면 콜백을 연결한다.

현재 코드는 core(공통), data/local(DB·Mapper), data/repositories(계약·Drift), data/services(조회·파싱·비교·반영), presentation(화면·공통 행)으로 구성한다. 상태는 StatefulWidget/FutureBuilder를 사용한다. providers 폴더는 초기 자리표시자이며 실제 Provider/Riverpod 사용 근거가 아니다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../docs/README.md)를 본다.

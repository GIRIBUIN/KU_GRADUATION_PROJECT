# DB 개선 증거 자료

작업 설명은 [개선 작업 기록](../../개선%20작업%20기록.md), 현재 구조는 [DB v6 관계도](../../diagrams/db-v6.md)를 참고한다.
파일명의 측정 시각은 UTC다. 작업 기록은 한국 시간 기준이며, 아래 결과는 2026-10-30 작업에서 확인했다.

| 확인할 내용 | 파일 |
| --- | --- |
| 최종 테스트·분석·APK·소스 해시 요약 | [validation-summary-v6-20261030.json](validation-summary-v6-20261030.json) |
| 변경 전 목록 조회 측정 | [task-list-2026-10-29T14-17-14-061288Z.json](task-list-2026-10-29T14-17-14-061288Z.json) |
| 변경 후 단독 실행 목록 조회 측정 | [task-list-2026-10-29T15-37-43-034316Z.json](task-list-2026-10-29T15-37-43-034316Z.json) |
| 변경 전 로직 문제 재현 | [contract-audit-2026-10-29T14-39-52-139024Z.json](contract-audit-2026-10-29T14-39-52-139024Z.json) |
| 변경 후 같은 시나리오 확인 | [contract-audit-2026-10-29T15-36-30-841250Z.json](contract-audit-2026-10-29T15-36-30-841250Z.json) |
| 최종 테스트 125건 통과 원본 | [validation-v6-final-20261030.jsonl](validation-v6-final-20261030.jsonl) |
| 정적 분석: 오류·경고 0, 기존 info 1 | [analyze-v6-20261030.txt](analyze-v6-20261030.txt) |
| 최종 Android APK 빌드 성공 | [build-v6-final-20261030.txt](build-v6-final-20261030.txt) |
| Galaxy S24 설치 성공 | [install-v6-20261030.json](install-v6-20261030.json) |
| 변경 전 측정·재현 코드 보관본 | [baseline-harness-v5.zip](baseline-harness-v5.zip) |

1,000개 조회의 중앙값은 96.2755 → 20.5745 ms, SELECT는 2,001 → 5회였다.
같은 Windows 환경의 예열된 메모리 SQLite와 합성 데이터 기준이다. 모바일·디스크·화면 성능 측정으로 해석하지 않는다.
다른 시각의 측정·중간 검증 결과도 삭제하지 않고 보존했다. 위 표는 비교에 선택한 결과를 가리킨다.

검증 요약 JSON은 기기 설치 **전**에 작성된 시점 기록이다. 이후 설치 성공은 별도 설치 JSON에 있다.
설치는 확인했으나 실제 기기 DB 이관·일정 보존·WebView 로그인·위젯·알림 동작은 아직 확인하지 않았다.
iOS 실행, 기기 간 동기화와 OCR도 미수행이다.

`source_git_blob_hashes`는 검증 당시 파일 내용의 Git blob 해시다. 커밋 전에도 동일 소스를 식별할 수 있도록 기록했다.
Git 이력의 시작점은 요약 JSON의 `git_base`이며, 이번 작업 브랜치는 `refactor/flutter-db-v6`다.

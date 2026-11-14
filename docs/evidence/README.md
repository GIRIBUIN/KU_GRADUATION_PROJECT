# 검증 원본 안내

원본 파일은 당시 실행 결과다. 현재 구현은 [현재 문서](../README.md), 수치 해석은 [검증 및 측정](../검증%20및%20측정.md)을 본다.
파일명의 UTC 시각·기록일·소스 해시와 실제 검증 범위를 확인한다.

| 폴더 | 내용 |
| --- | --- |
| [db](db/README.md) | v5 기준 측정·오류 재현·v6 이관/변경 후 측정·기준 harness |
| [db-v7](db-v7/README.md) | v7 목록·상위 폴더·미지정·이관 당시 검증 |
| [ecampus](ecampus/README.md) | 가져오기 검토·원자성·MISSING·알림·세션 및 응답 판정 보완 |
| [home-ui](home-ui/README.md) | 홈/Drawer/캘린더/설정/공통 행·서브 작업, 테스트 캡처 |
| [integration](integration/README.md) | 최신 위젯 통합·실기기 설치·브랜치 보관 및 main 단일화 |
| [commits](commits/README.md) | 2026-10-31 분할 커밋 당시 검증 |
| [documentation](documentation/README.md) | 2026-11-15 문서 정리의 링크·원본 보존·스키마 문서 점검 |

기존 JSON/JSONL/XML/TXT/이미지/ZIP을 수정하거나 실패 이력을 최종 통과처럼 바꾸지 않는다.
`uncommitted_changes`·`commit_or_push_performed` 등의 값은 **파일 생성 당시 상태**다.
같은 테스트가 여러 회차에 포함되므로 서로 다른 회차 숫자를 더하지 않는다.
캡처는 widget 테스트 렌더인지 실제 Android 화면인지 기록을 확인하며 구분한다.

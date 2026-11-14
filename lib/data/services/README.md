# 가져오기·표시·위젯 서비스

현재 기준: 2026-11-15.

http_ecampus_todo_client → default_ecampus_todo_service/parser → default_ecampus_sync_service/classifier → ecampus_sync_flow_service/apply_service 순서로 가져오기를 처리한다.

preview는 읽기 전용, 선택 반영은 현재 Drift transaction이다. CHANGED 현재 값 유지와 NEW 제외를 구분하고 MISSING은 완전한 응답에서만 검토한다. widget_update_service는 Task+목록으로 JSON을 만들고 native 위젯을 갱신한다. widget_background_refresh는 UI 없는 갱신 진입점이다. home_task_summary/calendar_task_index는 화면 조회 기준이다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../../../docs/README.md)를 본다.

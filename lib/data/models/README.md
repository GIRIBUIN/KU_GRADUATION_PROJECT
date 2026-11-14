# 데이터 모델·DTO

현재 기준: 2026-11-15.

task_models.dart에 Task·SubTask·Tag·Folder(목록)·FolderGroup이 있고 ecampus_models.dart에 파싱·비교·선택 모델이 있다.

Task.folderIds는 단일 목록을 위한 기존 화면 호환 이름이다. EcampusSyncMetadata는 별도 원본 행을 UI로 전달한다. home_view_options/home_period_preference/task_swipe_options는 저장 가능한 화면 설정이며 위젯 JSON 모델은 네이티브 렌더링 전달용이다. assignment.dart/task.dart는 예정 파일명이었고 현재 구현 파일이 아니다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../../../docs/README.md)를 본다.

# 저장소 계약과 Drift 구현

현재 기준: 2026-11-15.

task/sub_task/tag/folder/notification/settings_repository.dart와 대응 drift_* 구현을 사용한다. 이미 실제 DB·화면에 연결되어 있다.

FolderRepository는 현재 목록 계약이며 GroupedListRepository가 상위 폴더·목록 이동을 추가한다. TransactionalTaskRepository.atomic/recordImport를 가져오기 batch에 사용한다. 완료·휴지통은 Task 시각, 제외는 원본 import_state다. 일반 알림 규칙과 기기 예약 상태도 분리한다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../../../docs/README.md)를 본다.

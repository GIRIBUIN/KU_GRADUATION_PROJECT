# Task DTO와 저장 호환 명세

현재 기준: 2026-11-15. 저장 테이블은 [데이터 모델](../데이터%20모델.md), 화면 DTO는 [task_models.dart](../../lib/data/models/task_models.dart)와 [TaskMapper](../../lib/data/local/mappers/task_mapper.dart)를 따른다.

| DTO | 의미 |
| --- | --- |
| Task.id/title/dueDate/memo/priority/sortOrder | 사용자 작업 값 |
| Task.origin | 연결 원본 여부에서 변환. tasks.origin 컬럼이 아님 |
| Task.status | 완료/삭제 시각 또는 제외 원본 projection에서 변환. tasks.status 컬럼이 아님 |
| Task.ecampus | 별도 원본 snapshot을 화면에 전달하는 metadata |
| Task.folderIds / Task.listId | 기존 화면 호환 단일 목록 소속. 복수 폴더 관계가 아님 |
| Task.parentTaskId | 남은 호환 필드. 현재 서브 기능은 별도 SubTask.taskId 사용 |
| Folder / FolderGroup | 목록 / 상위 폴더 |
| NotificationSetting.daysBeforeDue | 현재 분 단위 offset_minutes의 호환 이름 |

## 상태 전이

- 개인 생성 또는 NEW 가져오기 → active Task.
- active ↔ completed: completed_at 설정/해제.
- active/completed → deleted: deleted_at 설정. 복원은 삭제 시각만 해제하므로 이전 완료 상태를 보존할 수 있다.
- NEW 제외: Task 없이 ignored 원본 생성.
- CHANGED 현재 값 유지: 기존 Task 상태 유지 + 원본 snapshot 갱신. active → excluded 전이가 아니다.
- 제외 해제: 원본을 unreviewed로 바꿔 다음 조회에서 후보로 허용. 즉시 Task 생성 아님.
- 영구 삭제: 사용자 작업과 관련 행을 정리하고 삭제 식별 기록을 남긴다. 연결 원본은 ignored로 분리해 자동 중복 재생성을 막는다.

제외 항목은 UI의 TaskStatus.excluded로 보여도 실제 Task 행이 아니다.
Task.isArchived는 완료·삭제·제외를 묶는 helper이고 목록 보관 UI의 존재를 뜻하지 않는다.

## 화면 동작

서브 작업 유무에 따른 터치/펼침, 길게 누르기 상세, 휴지통·제외 선택은 [화면 흐름](../화면%20흐름.md)을 따른다.
서브 전체 완료가 부모 자동 완료로 이어지지 않는다. 변경 반영의 비교 필드는 [eCampus 명세](e-campus%20동기화%20명세.md)를 따른다.

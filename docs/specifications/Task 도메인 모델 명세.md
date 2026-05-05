# Task 도메인 모델 명세

## 1. Task

앱의 모든 작업은 Task로 관리한다.
개인 작업과 e-campus 작업은 같은 Task 구조를 사용하되, e-campus 작업에는 동기화 메타데이터를 추가한다.

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | String | 예 | 앱 내부 Task ID |
| `origin` | TaskOrigin | 예 | `personal`, `ecampus` |
| `status` | TaskStatus | 예 | 현재 상태 |
| `title` | String | 예 | 사용자가 보는 제목 |
| `dueDate` | DateTime? | 아니오 | 사용자가 보는 마감일 |
| `priority` | TaskPriority? | 아니오 | 직접 지정한 우선순위 |
| `memo` | String? | 아니오 | 메모 |
| `parentTaskId` | String? | 아니오 | 상위 Task ID |
| `createdAt` | DateTime | 예 | 생성 시각 |
| `updatedAt` | DateTime | 예 | 수정 시각 |
| `completedAt` | DateTime? | 아니오 | 완료 시각 |
| `deletedAt` | DateTime? | 아니오 | 삭제 시각 |

## 2. TaskOrigin

| 값 | 설명 |
| --- | --- |
| `personal` | 사용자가 직접 만든 작업 |
| `ecampus` | e-campus에서 가져온 작업 |

## 3. TaskStatus

| 값 | 설명 |
| --- | --- |
| `active` | 진행 중 |
| `completed` | 완료됨 |
| `deleted` | 삭제됨 |
| `excluded` | e-campus에서 발견됐지만 가져오지 않음 |

`excluded`는 e-campus 항목에만 사용한다.

## 4. 상태 전이

```text
active -> completed
active -> deleted
completed -> active
deleted -> active
ecampus 신규 후보 -> excluded
excluded -> active
```

삭제는 즉시 영구 삭제하지 않고 `deleted` 상태로 남긴다.

## 5. EcampusSyncMetadata

e-campus 작업에만 붙는 원본 추적 정보이다.

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `sourceKey` | String | 예 | e-campus 항목 식별용 내부 키 |
| `sourceTitle` | String? | 아니오 | e-campus 원본 제목 |
| `sourceDueDate` | DateTime? | 아니오 | e-campus 원본 마감일 |
| `sourceCourse` | String? | 아니오 | 과목명 |
| `sourceType` | String? | 아니오 | 과제, 온라인강의 등 |
| `lastSyncedAt` | DateTime? | 아니오 | 마지막 동기화 시각 |

`sourceKey`는 e-campus HTML에 그대로 존재하는 필드명이 아니다.
파싱한 값을 조합해서 앱 내부에서 만든다.

## 6. SubTask

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | String | 예 | SubTask ID |
| `taskId` | String | 예 | 상위 Task ID |
| `title` | String | 예 | 제목 |
| `isDone` | Boolean | 예 | 완료 여부 |
| `createdAt` | DateTime | 예 | 생성 시각 |
| `updatedAt` | DateTime | 예 | 수정 시각 |

## 7. Tag

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | String | 예 | 태그 ID |
| `name` | String | 예 | 태그 이름 |
| `color` | String | 예 | 표시 색상 값 |
| `defaultPriority` | TaskPriority? | 아니오 | 태그 기본 우선순위 |
| `createdAt` | DateTime | 예 | 생성 시각 |
| `updatedAt` | DateTime | 예 | 수정 시각 |

## 8. Folder

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | String | 예 | 폴더 ID |
| `name` | String | 예 | 폴더 이름 |
| `color` | String? | 아니오 | 표시 색상 값 |
| `icon` | String? | 아니오 | 아이콘 이름 |
| `createdAt` | DateTime | 예 | 생성 시각 |
| `updatedAt` | DateTime | 예 | 수정 시각 |

## 9. NotificationSetting

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | String | 예 | 알림 ID |
| `taskId` | String | 예 | 연결된 Task ID |
| `enabled` | Boolean | 예 | 알림 사용 여부 |
| `daysBeforeDue` | Int | 예 | 마감 며칠 전 알림인지 |
| `notifyTime` | Time | 예 | 알림 시간 |
| `scheduledAt` | DateTime? | 아니오 | 실제 예약된 알림 시각 |

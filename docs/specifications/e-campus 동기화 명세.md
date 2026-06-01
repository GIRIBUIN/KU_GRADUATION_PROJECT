# e-campus 동기화 명세

## 1. 목적

e-campus 체크리스트 HTML을 읽어 앱의 Task로 가져오기 위한 파싱, 식별, 분류 규칙을 정의한다.

## 2. 파싱 결과 모델

HTML 파싱 직후에는 Task로 바로 저장하지 않고 `ParsedEcampusTask` 형태로 다룬다.

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `sourceKey` | String | 앱 내부 동기화 식별 키 |
| `title` | String | 원본 제목 |
| `course` | String | 과목명 |
| `dueDate` | DateTime? | 원본 마감일 |
| `dueLabel` | String? | HTML에 표시된 마감 문자열 |
| `dDay` | Int? | D-day 값 |
| `type` | EcampusTaskType | `report`, `project`, `lecture`, `quiz`, `exam`, `unknown` |
| `rawLectureId` | String? | `goLecture(...)` 첫 번째 인자 또는 `kj_*` 값 |
| `rawItemId` | String? | `goLecture(...)` 두 번째 인자 |
| `rawType` | String? | `goLecture(...)` 세 번째 인자 또는 `gubun_*` 값 |

## 3. HTML 기준 값

현재 확인한 체크리스트 HTML 기준으로 다음 값을 사용할 수 있다.

```html
<div class="todo_wrap" onclick="goLecture('A20261...', '13429606', 'project')">
  <input type="hidden" id="kj_0" value="A20261..." />
  <input type="hidden" id="gubun_0" value="project" />
  <div class="todo_title">...</div>
  <div class="todo_subjt">...</div>
  <span class="todo_d_day">D-6</span>
  <span class="todo_date">...</span>
</div>
```

## 4. sourceKey 생성 규칙

`sourceKey`는 e-campus HTML에 있는 단일 필드가 아니다.
앱에서 동기화를 위해 만드는 내부 식별 키이다.

기본 규칙:

```text
sourceKey = rawLectureId + ":" + rawItemId + ":" + rawType
```

예:

```text
A20261BBAB590693222001:13429606:project
```

현재 구현은 `rawLectureId`, `rawItemId`, `rawType` 중 하나라도 없으면 fallback key를 만들지 않고 파싱 실패 항목으로 분리한다.

## 5. 동기화 분류

### 신규 항목

```text
parsed.sourceKey가 DB에 없음
```

사용자가 선택하면 새 Task를 생성한다.

### 이미 가져온 항목

```text
parsed.sourceKey가 active 또는 completed Task에 존재
원본 정보 변경 없음
```

동기화 결과에서 가져올 항목으로 보여주지 않는다.

### 업데이트 후보

```text
parsed.sourceKey가 DB에 있음
sourceTitle, sourceDueDate, sourceCourse, sourceType 중 하나가 달라짐
```

자동 반영하지 않는다.
사용자가 선택한 경우에만 Task 표시 값을 원본 기준으로 갱신한다.

### 완료된 항목

```text
Task.status = completed
```

다시 신규 항목으로 표시하지 않는다.

### 삭제된 항목

```text
Task.status = deleted
```

목록에는 숨기고, 다음 동기화 때 같은 항목은 가져오지 않을 항목으로 분류한다.

### 제외된 항목

```text
Task.status = excluded
```

사용자가 가져오지 않기로 선택한 e-campus 항목이다.
다음 동기화 때 신규 항목으로 다시 표시하지 않는다.

## 6. 원본에서 사라진 항목

현재 구현은 동기화가 오류 없이 끝났을 때, 기존 e-campus task가 이번 체크리스트에 없고 마감 전이면 완료 처리한다.

완료 처리 조건:

- 기존 task 상태가 `active`
- `sourceKey`가 있음
- 이번 동기화 결과에 같은 `sourceKey`가 없음
- `sourceDueDate` 또는 `dueDate`가 동기화 시각 이후임

마감일이 지났거나 마감일이 없는 task는 자동 완료하지 않고 기존 상태를 유지한다.

## 7. 실패 처리

다음 경우에는 동기화 실패 또는 부분 실패로 처리한다.

- 로그인 실패
- 세션 만료
- 네트워크 오류
- HTML 구조 변경
- 필수 값 파싱 실패
- sourceKey 생성 실패

파싱 실패가 발생해도 앱 전체가 중단되면 안 된다.
실패 항목은 동기화 결과에서 오류 항목으로 분리할 수 있다.

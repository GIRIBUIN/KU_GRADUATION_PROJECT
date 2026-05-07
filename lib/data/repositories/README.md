# repositories

앱 데이터 저장소에 접근하는 인터페이스를 둔다.
UI와 application 로직은 가능하면 DB나 service 구현체를 직접 호출하지 않고 repository를 통해 데이터를 읽고 쓴다.

## 현재 파일

- `task_repository.dart`: Task 조회, 생성, 수정, 상태 변경, 삭제/복구
- `drift_task_repository.dart`: Drift DB 기반 TaskRepository 구현
- `tag_repository.dart`: Tag 조회, 생성, 수정, 삭제
- `folder_repository.dart`: Folder 조회, 생성, 수정, 삭제
- `notification_repository.dart`: Task별 알림 설정 저장/삭제
- `settings_repository.dart`: 자동 동기화, 계정 저장 여부 등 앱 설정

## 구현 원칙

- 이 폴더에는 인터페이스를 먼저 둔다.
- 실제 로컬 DB 스키마는 `lib/data/local`의 Drift DB를 기준으로 한다.
- repository 구현체는 후속 커밋에서 Drift DB를 감싸는 형태로 추가한다.
- 저장 방식이 바뀌어도 인터페이스의 의미는 유지한다.

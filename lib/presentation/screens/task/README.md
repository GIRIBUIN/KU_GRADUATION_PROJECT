# 할 일 생성·상세

현재 기준: 2026-11-15.

task_create_screen.dart(전체/빠른 추가), task_detail_screen.dart(상세 Bottom Sheet), widget_task_create_screen.dart(위젯 팝업)가 현재 파일이다.

가져온 eCampus 할 일도 사용자 제목·마감·목록·태그·메모 등을 수정할 수 있다. 원본 snapshot은 별도로 보존한다. 위젯 팝업은 제목·마감·목록 선택이며 태그 편집 UI를 두지 않는다. 서브 작업 CRUD는 기존 SubTaskRepository를 사용한다.

전체 구조·정책·실행 방법은 [프로젝트 문서](../../../../docs/README.md)를 본다.

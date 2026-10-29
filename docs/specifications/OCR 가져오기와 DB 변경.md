# OCR 가져오기와 DB 변경

기준일: 2026-10-29. 사용자 제안에 따른 설계 변경 기록이다. 아직 캡처·OCR 구현이나 실기기 측정은 수행하지 않았다.
우선순위 메모: 사용자는 WebView 개발용 검증·포트폴리오를 먼저 마치고 OCR을 후속 과제로 미루는 방향을 검토 중이다. 이 문서는 후속 아이디어로 보존하며 현재 DB 구현의 선행 과제로 삼지 않는다.

## 가능한 흐름과 먼저 확인할 것

Android에서는 화면 캡처 승인 → MediaProjection 서비스 → 사용자가 eCampus 앱에서 이동·스크롤 → 안정된 화면 OCR → 누적 → 종료 → KUTODO 검토·선택 반영 흐름을 검토한다. 세션마다 캡처 동의를 받고, Android 14 이상에서는 mediaProjection 전경 서비스 선언이 필요하다. 안내 오버레이는 별도 권한·지원 여부를 확인하며 필수 OCR 기능과 분리한다.

대상 eCampus 앱의 할 일 화면이 실제로 캡처되는지 먼저 확인한다. FLAG_SECURE 등으로 보호된 화면은 이 설계의 입력으로 사용할 수 없다. 현재 해당 앱의 설정은 확인하지 않았다.

iOS는 Android와 같은 오버레이 흐름을 전제로 하지 않는다. ReplayKit의 시스템 방송 선택 UI·확장 방식 등을 별도 검증한다. Apple의 iOS ScreenCaptureKit 샘플은 iOS 27 이상·베타 문서로 표시돼 있으므로 지원 기기 전체의 기본 전제로 삼지 않는다. 공통 첫 검증은 사용자가 선택한 스크린샷 여러 장 → OCR → 검토 방식으로 진행할 수 있다.

한국어 OCR은 ML Kit Text Recognition v2 등으로 검증 가능하다. 사용할 엔진·모델·Flutter 연결 방식은 아직 결정하지 않았다.

학교가 외부 연동을 제공하지 않는다는 사용자 전달 내용은 기록하되, 그것만으로 OCR 방식의 허용·금지를 확정하지 않는다. 이 기록은 기술 검토이며 학교의 허용을 확인한 자료가 아니다.

## 저장과 반영 규칙

`캡처 화면 → ImportObservation → 후보 정리·기존 일정 매칭 → 사용자 검토 → Task와 EcampusItem 저장`

- Task는 사용자 일정, EcampusItem은 앱 내부의 출처 항목이다. 둘 다 내부 UUID로 식별한다. 화면에 보이는 제목·과목·마감일이나 그 해시를 ID로 사용하지 않는다.
- 외부 원본 ID가 있으면 externalKey에 저장하고 없으면 null이다. Kotlin의 원본 복합키 필수 제약은 OCR 입력에 적용하지 않는다.
- ImportSession은 입력 방식(live_capture / screenshots), 계정 범위, 시작·종료 시각, 진행 상태를 기록한다. OCR에서 전체 목록을 확보했다고 가정하지 않는다.
- ImportObservation은 원문·파싱값·검토 후 값·관측 시각·프레임 근거·선택 결과를 구분한다. 화면 이미지 해시와 위치는 관측 근거이지 과제의 영구 식별자가 아니다. 엔진이 제공하지 않는 confidence는 만들어 넣지 않는다.
- 화면 전환·스크롤 중인 프레임과 잘린 카드는 보류한다. 안내 오버레이 영역은 OCR 대상에서 제외한다. 할 일 화면 감지는 휴리스틱이므로 오인식 시 사용자가 다시 지정할 수 있어야 한다.
- OCR의 과목명·제목·날짜는 틀리거나 잘릴 수 있다. 연도·시각이 안 보이면 기준 시각과 원문을 남기고 불확실한 값은 검토 대상으로 표시한다.
- 스크롤 중 같은 카드를 다시 본 경우에는 프레임·카드 근거를 함께 써서 후보를 묶는다. 별개 과제가 제목·과목·마감일이 같을 수도 있어 필드 조합의 DB UNIQUE 제약으로 강제 병합하지 않는다.
- 재가져오기에서 유사한 일정은 기존 항목 후보로 제시한다. 사용자가 새 일정 추가 / 기존 일정 연결·선택 필드 갱신 / 이번 인식 무시를 결정한다. 마감일이 바뀌면 해시가 달라지므로 해시 일치만으로 변경을 찾지 않는다.
- **이번 화면에 안 나온 일정은 그대로 둔다.** 스크롤 누락·탭·기간·필터가 있을 수 있다. 가져오기 종료나 빈 OCR 결과를 누락·완료·삭제의 근거로 삼지 않는다.
- 검토 확정 후 한 트랜잭션에서 선택 결과를 반영한다. 같은 세션·후보의 확정 버튼을 반복 눌러도 같은 변경이 중복 실행되지 않도록 반영 이력을 기록한다.
- 취소·OCR 오류는 기존 Task를 변경하지 않는다. 가져온 뒤 사용자가 수정한 메모·태그·폴더는 재인식으로 덮어쓰지 않는다.
- 원본 스크린샷 저장은 필수로 하지 않는다. 필요한 검토용 부분 이미지와 OCR 근거의 보관 기간을 정하고, 전체 영상·화면을 기본적으로 기기 간 동기화하지 않는다.

## 기기 간 동기화와의 구분

OCR 가져오기는 외부 화면을 사용자 일정으로 바꾸는 입력 기능이다. 기기 간 동기화는 확정된 UUID 기반 일정·태그·폴더와 사용자 선택을 서버를 통해 전달하는 기능이다. 서버 동기화를 위해 eCampus 원본 번호가 반드시 필요한 것은 아니다.

다만 서로 다른 두 기기가 같은 과제를 각각 새로 가져오면 서로 다른 UUID가 생길 수 있다. 가능하면 최신 앱 데이터 수신 후 매칭 후보를 비교하고, 동시에 생성된 항목은 나중에 중복 후보로 검토한다. OCR만으로 동일 과제 여부를 항상 보장한다고 주장하지 않는다.

## 첫 검증과 남길 측정값

1. Android·iOS에서 할 일 화면 스크린샷이 가능한지 확인하고 OS·앱 버전을 기록한다. 실시간 화면 수집 가능성과는 따로 기록한다.
2. 소수의 스크린샷과 사람이 확인한 정답으로 제목·과목·날짜 추출을 검증한다. 겹친 화면, 잘린 카드, 같은 이름의 서로 다른 과제, 날짜 변경을 포함한다.
3. 화면별 OCR 시간(ms), 처리 화면 수, 보류 화면 수, 인식 카드 수, 정리 후 후보 수, 중복 누락·잘못 병합한 수, 필드별 정답 수/검증 대상 수, 사용자 수정 수를 원본 값으로 남긴다.
4. 검토 전후 Task 건수·내용, 취소 시 무변경, 확정 반복 시 중복 없음, 다른 기기에서 다시 가져온 경우를 확인한다.

측정 엔진·모델 버전·이미지 크기·기기·원본 입력·기대값을 함께 보관한다. 직접 확인하지 않은 전체 eCampus 목록에 대한 재현율은 계산하지 않는다. 기존 PC DB 조회 측정과 OCR 실기기 측정은 별개다.

## 공식 기술 근거

- [Android MediaProjection](https://developer.android.com/media/grow/media-projection): 세션 동의, 전경 서비스, 화면 수집 API.
- [Android 오버레이 권한](https://developer.android.com/reference/android/Manifest.permission#SYSTEM_ALERT_WINDOW): 다른 앱 위 창에 대한 권한.
- [Android 보호 화면](https://developer.android.com/security/fraud-prevention/activities): FLAG_SECURE와 캡처 제한.
- [Apple 방송 선택 UI](https://developer.apple.com/documentation/replaykit/rpsystembroadcastpickerview), [방송 샘플 처리](https://developer.apple.com/documentation/replaykit/rpbroadcastsamplehandler): iOS 화면 수집 검증 경로.
- [Apple iOS ScreenCaptureKit 샘플](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-on-ios): iOS 27 이상·베타 표시 확인.
- [ML Kit Text Recognition v2](https://developers.google.com/ml-kit/vision/text-recognition/v2): 한국어 지원과 텍스트 구조 인식.

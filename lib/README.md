# lib

앱의 모든 소스코드가 위치하는 루트 디렉토리.
레이어드 아키텍처 기반으로 데이터 처리와 UI를 분리해서 구성함.

## 구조
```
lib/
├── core/                   # 앱 전체 공통 요소
│   ├── constants/          # URL, 엔드포인트 등 상수
│   └── utils/              # 날짜 계산 등 헬퍼 함수
│
├── data/                   # 데이터 처리 레이어
│   ├── models/             # 데이터 구조 정의 (Assignment, Task)
│   ├── services/           # 네트워크 요청, HTML 파싱
│   └── repositories/       # services 추상화, 상위 레이어에 인터페이스 제공
│
├── presentation/           # UI 레이어
│   ├── screens/
│   │   ├── login/          # WebView 로그인 화면
│   │   ├── home/           # 일정 통합 메인 화면
│   │   ├── task/           # 개인 일정 추가/수정 화면
│   │   └── widget_settings/# 홈 화면 위젯 설정
│   └── widgets/            # 재사용 UI 컴포넌트
│
├── providers/              # 상태 관리
└── main.dart               # 앱 진입점
```

## 데이터 흐름
```
eCampus 서버
    ↓ POST 요청
services/       → HTML 파싱
    ↓
repositories/   → 데이터 정제 및 추상화
    ↓
providers/      → 상태 관리
    ↓
presentation/   → UI 렌더링
```
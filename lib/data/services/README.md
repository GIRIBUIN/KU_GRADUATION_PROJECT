# services

네트워크 요청 및 WebView 세션 처리 등 저수준 작업.

## 예정 파일
- `webview_service.dart`  : WebView 로그인 후 세션 쿠키 추출 및 암호화 저장
- `ecampus_service.dart`  : todo_list 엔드포인트 POST 요청 및 HTML 파싱

## 데이터 흐름
WebView 로그인 → 세션 추출 → POST 요청 → HTML 파싱 → 모델 변환
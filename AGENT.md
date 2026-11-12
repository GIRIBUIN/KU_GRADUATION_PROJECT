{\rtf1\ansi\ansicpg949\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 \
# Project Guidelines\
\
## Technology\
- Flutter / Dart\
- Android and iOS application\
\
## Architecture\
- Preserve the existing architecture.\
- Reuse existing Models and Repositories.\
- Separate UI and business logic.\
- Follow existing naming conventions.\
\
## Development Rules\
- Avoid unnecessary dependencies.\
- Do not remove existing functionality.\
- Make minimal, focused changes.\
- Explain significant architectural changes before implementation.\
\
## Verification\
- Run `flutter analyze` after modifications.\
- Run relevant tests when available.\
- Report any existing or newly introduced errors.\
- Summarize changed files.\
\
## Git and Security\
- Never commit secrets or credentials.\
- Do not push, merge, or deploy without explicit permission.\
- Do not discard uncommitted changes.\
- Ask before destructive commands.\
\
## Communication\
- Respond in Korean.\
- Explain the cause of errors and the changes made.\

# Home Widget Development Guidelines

## Project
- Flutter 기반 대학생 일정 관리 앱
- Android 홈 위젯 2종:
  1. 오늘 마감 일정
  2. 이번 주 마감 일정

## General Rules
- 기존 프로젝트 아키텍처와 코딩 스타일을 유지한다.
- 현재 사용 중인 상태 관리, DB, Repository 구조를 재사용한다.
- 기존 기능을 임의로 삭제하거나 변경하지 않는다.
- Android 위젯 관련 변경은 현재 구현 기술을 우선 사용한다.
- 불필요한 패키지 추가 및 대규모 리팩터링을 피한다.
- 다른 기능이나 화면을 수정해야 할 경우 이유를 설명한다.
- 각 단계의 작업 완료 후 변경 파일과 테스트 결과를 보고한다.

## Widget Requirements
- 오늘 마감 위젯은 하루 마감 일정을 모두 조회한다.
- 이번 주 마감 위젯은 월요일~일요일 마감 일정을 모두 조회한다.
- 오늘 위젯은 페이지당 3개, 이번 주 위젯은 5개를 표시한다.
- 이전/다음 버튼으로 페이지를 전환한다.
- 완료 및 미완료 일정을 모두 조회할 수 있어야 한다.
- 체크 이벤트 직후 데이터를 저장하고 위젯을 갱신한다.
- 두 위젯에 공통으로 사용할 일정 등록 화면을 제공한다.
- 등록 항목은 제목, 마감 날짜, 마감 시간, 타입이다.
- 타입은 학업과 개인 두 가지로 제한한다.

## Implementation Rules
- 페이지 계산 및 정렬 로직은 가능한 한 UI와 분리한다.
- 일정을 식별할 때 행 인덱스 대신 고유 ID를 사용한다.
- 각 위젯 인스턴스의 페이지 상태를 독립적으로 관리한다.
- 기존 우선순위 규칙을 먼저 확인한 뒤 유지한다.
- 임의의 데이터 저장 경로나 DB 스키마를 만들지 않는다.
- 구현 후 가능한 범위에서 빌드, 정적 분석, 테스트를 수행한다.
- 테스트하지 못한 동작은 테스트 완료로 보고하지 않는다.

}

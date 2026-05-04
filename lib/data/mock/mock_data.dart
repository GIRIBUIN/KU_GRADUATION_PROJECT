import 'package:flutter/material.dart';

import '../models/task_models.dart';

class MockData {
  static const majorTag = TaskTag(
    name: '전공',
    color: Color(0xFF35B921),
    defaultPriority: TaskPriority.high,
  );
  static const liberalTag = TaskTag(
    name: '교양',
    color: Color(0xFF218CEB),
    defaultPriority: TaskPriority.medium,
  );
  static const teamTag = TaskTag(
    name: '팀플',
    color: Color(0xFFF58A00),
    defaultPriority: TaskPriority.high,
  );
  static const personalTag = TaskTag(
    name: '개인',
    color: Color(0xFF008F83),
    defaultPriority: TaskPriority.medium,
  );

  static const tags = [majorTag, liberalTag, teamTag, personalTag];

  static const folders = [
    TaskFolder(name: '이번 주 집중', count: 5),
    TaskFolder(name: '졸업작품', count: 7),
    TaskFolder(name: '시험기간', count: 4),
  ];

  static const tasks = [
    TaskItem(
      id: 'os-team-project',
      title: '운영체제 팀플 과제',
      dueLabel: '5월 7일',
      source: TaskSource.ecampus,
      priority: TaskPriority.high,
      tags: [majorTag, teamTag],
      sourceNote: 'e-campus에서 가져온 작업',
      memo: '팀원별 파트 확인 후 최종 제출',
      subTasks: [
        SubTask(title: '자료 조사', isDone: true),
        SubTask(title: '보고서 초안'),
        SubTask(title: 'PPT 제작'),
        SubTask(title: '제출 확인', isDone: true),
      ],
    ),
    TaskItem(
      id: 'data-structure-submit',
      title: '자료구조 과제 제출',
      dueLabel: '5월 9일',
      source: TaskSource.ecampus,
      priority: TaskPriority.high,
      tags: [majorTag],
    ),
    TaskItem(
      id: 'graduation-feature-design',
      title: '졸업작품 기능 설계',
      dueLabel: '5월 15일',
      source: TaskSource.personal,
      priority: TaskPriority.medium,
      tags: [majorTag, personalTag],
      subTasks: [
        SubTask(title: '화면 흐름 정리', isDone: true),
        SubTask(title: '테스트 시나리오 정리', isDone: true),
        SubTask(title: '발표 자료 반영'),
        SubTask(title: '팀 리뷰'),
        SubTask(title: '최종 제출'),
      ],
    ),
    TaskItem(
      id: 'online-class',
      title: '온라인 강의 수강',
      dueLabel: '오늘',
      source: TaskSource.ecampus,
      priority: TaskPriority.low,
      tags: [liberalTag],
    ),
    TaskItem(
      id: 'liberal-quiz',
      title: '교양 퀴즈',
      dueLabel: '5월 8일',
      source: TaskSource.ecampus,
      priority: TaskPriority.medium,
      tags: [liberalTag],
    ),
    TaskItem(
      id: 'data-structure-review',
      title: '자료구조 복습',
      dueLabel: '5월 20일',
      source: TaskSource.personal,
      priority: TaskPriority.low,
      tags: [majorTag, personalTag],
    ),
  ];

  static final todayTasks = [tasks[0], tasks[2], tasks[3]];

  static final upcomingTasks = [
    const TaskItem(
      id: 'campus-meeting-note',
      title: '캡스톤 회의록 정리',
      dueLabel: '5월 6일',
      source: TaskSource.personal,
      priority: TaskPriority.medium,
      tags: [personalTag],
    ),
    tasks[1],
    tasks[4],
  ];

  static const syncImportCandidates = [
    SyncCandidate(
      title: '자료구조 과제 제출',
      dueLabel: '5월 15일 (목)',
      statusLabel: '신규',
      statusColor: Color(0xFF148A45),
    ),
    SyncCandidate(
      title: '운영체제 팀플 과제',
      dueLabel: '5월 20일 (화)',
      statusLabel: '신규',
      statusColor: Color(0xFF148A45),
    ),
    SyncCandidate(
      title: '온라인 강의 수강',
      dueLabel: '5월 25일 (일)',
      statusLabel: '신규',
      statusColor: Color(0xFF148A45),
    ),
    SyncCandidate(
      title: '캡스톤 회의록 정리',
      dueLabel: '5월 12일 (월)',
      statusLabel: '업데이트',
      statusColor: Color(0xFFE06B00),
      changeNote: '마감일 변경: 5월 10일 -> 5월 12일',
    ),
  ];

  static const syncExcludedCandidates = [
    SyncCandidate(
      title: '교양 퀴즈',
      dueLabel: '5월 5일 (월)',
      statusLabel: '완료',
      statusColor: Color(0xFF9CA3AF),
      isSelected: false,
    ),
    SyncCandidate(
      title: '삭제된 과제',
      dueLabel: '4월 28일 (월)',
      statusLabel: '삭제됨',
      statusColor: Color(0xFF9CA3AF),
      isSelected: false,
    ),
    SyncCandidate(
      title: '이미 가져온 과제',
      dueLabel: '5월 1일 (목)',
      statusLabel: '제외됨',
      statusColor: Color(0xFF9CA3AF),
      isSelected: false,
    ),
  ];
}

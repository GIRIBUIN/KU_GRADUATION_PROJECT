import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/models/task_models.dart';
import 'package:ku_task_management/data/services/ecampus_todo_parser.dart';

void main() {
  final parser = EcampusTodoParser(now: () => DateTime(2026, 5, 14, 10));

  group('EcampusTodoParser', () {
    test('parses normal todo items from goLecture arguments', () {
      final result = parser.parse('''
        <div class="todo_wrap on"
            onclick="goLecture('A20261BBAB590693222001','13429606','project')">
          <input type="hidden" id="kj_0" value="A20261BBAB590693222001"/>
          <input type="hidden" id="gubun_0" value="project"/>
          <div class="todo_title">운영체제 팀플 과제</div>
          <div class="todo_subjt">운영체제</div>
          <div class="todo_date">
            <span class="todo_d_day">D-6</span>
            <span class="todo_date">5월 20일 (화)</span>
          </div>
        </div>
      ''');

      expect(result.failures, isEmpty);
      expect(result.tasks.length, 1);

      final task = result.tasks.single;
      expect(task.sourceKey, 'A20261BBAB590693222001:13429606:project');
      expect(task.title, '운영체제 팀플 과제');
      expect(task.course, '운영체제');
      expect(task.type, EcampusTaskType.project);
      expect(task.dueDate, DateTime(2026, 5, 20, 23, 59));
      expect(task.dDay, 6);
      expect(task.dueLabel, '5월 20일 (화)');
    });

    test('ignores no_data placeholder items', () {
      final result = parser.parse('''
        <div class="todo_wrap no_data" id="no_data">결과 없음</div>
      ''');

      expect(result.tasks, isEmpty);
      expect(result.failures, isEmpty);
    });

    test('uses kj and gubun hidden values as source field fallback', () {
      final result = parser.parse('''
        <div class="todo_wrap on" onclick="goLecture('', '13429606', '')">
          <input type="hidden" id="kj_0" value="A20261BBAB590693222001"/>
          <input type="hidden" id="gubun_0" value="report"/>
          <div class="todo_title">자료구조 과제 제출</div>
          <div class="todo_subjt">자료구조</div>
          <div class="todo_date">
            <span class="todo_d_day">D+1</span>
            <span class="todo_date">5월 10일 (일)</span>
          </div>
        </div>
      ''');

      expect(result.failures, isEmpty);
      expect(
        result.tasks.single.sourceKey,
        'A20261BBAB590693222001:13429606:report',
      );
      expect(result.tasks.single.type, EcampusTaskType.report);
      expect(result.tasks.single.dueDate, DateTime(2026, 5, 13, 23, 59));
      expect(result.tasks.single.dDay, -1);
    });

    test('uses due label time when present', () {
      final result = parser.parse('''
        <div class="todo_wrap on"
            onclick="goLecture('A20261BBAB590693222001','13429606','quiz')">
          <div class="todo_title">자료구조 퀴즈</div>
          <div class="todo_subjt">자료구조</div>
          <div class="todo_date">
            <span class="todo_d_day">D-2</span>
            <span class="todo_date">5월 16일 (토) 18:30</span>
          </div>
        </div>
      ''');

      expect(result.failures, isEmpty);
      expect(result.tasks.single.dueDate, DateTime(2026, 5, 16, 18, 30));
      expect(result.tasks.single.dueLabel, '5월 16일 (토) 18:30');
    });

    test('falls back to due label date when D-Day is missing', () {
      final result = parser.parse('''
        <div class="todo_wrap on"
            onclick="goLecture('A20261BBAB590693222001','13429606','report')">
          <div class="todo_title">컴퓨터구조 보고서</div>
          <div class="todo_subjt">컴퓨터구조</div>
          <div class="todo_date">
            <span class="todo_date">5월 21일 (목)</span>
          </div>
        </div>
      ''');

      expect(result.failures, isEmpty);
      expect(result.tasks.single.dueDate, DateTime(2026, 5, 21, 23, 59));
      expect(result.tasks.single.dueLabel, '5월 21일 (목)');
    });

    test('generates due label fallback from D-Day when label is missing', () {
      final result = parser.parse('''
        <div class="todo_wrap on"
            onclick="goLecture('A20261BBAB590693222001','13429606','report')">
          <div class="todo_title">알고리즘 과제</div>
          <div class="todo_subjt">알고리즘</div>
          <div class="todo_date">
            <span class="todo_d_day">D-3</span>
          </div>
        </div>
      ''');

      expect(result.failures, isEmpty);
      expect(result.tasks.single.dueDate, DateTime(2026, 5, 17, 23, 59));
      expect(result.tasks.single.dueLabel, '5월 17일');
    });

    test('records failures when required values are missing', () {
      final result = parser.parse('''
        <div class="todo_wrap on">
          <div class="todo_title"></div>
          <div class="todo_subjt">자료구조</div>
        </div>
      ''');

      expect(result.tasks, isEmpty);
      expect(result.failures.length, 1);
      expect(result.failures.single.reason, contains('missing title'));
      expect(
        result.failures.single.reason,
        contains('missing source key fields'),
      );
      expect(result.failures.single.rawHtml, contains('todo_wrap'));
    });
  });
}

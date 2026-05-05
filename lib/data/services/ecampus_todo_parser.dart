import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/ecampus_models.dart';
import '../models/task_models.dart';

class EcampusTodoParser {
  const EcampusTodoParser();

  EcampusTodoParseResult parse(String html) {
    final document = html_parser.parse(html);
    final tasks = <ParsedEcampusTask>[];
    final failures = <EcampusParseFailure>[];

    for (final item in document.querySelectorAll('div.todo_wrap')) {
      if (item.id == 'no_data' || item.classes.contains('no_data')) {
        continue;
      }

      final parsed = _parseItem(item);
      if (parsed.failure != null) {
        failures.add(parsed.failure!);
      } else if (parsed.task != null) {
        tasks.add(parsed.task!);
      }
    }

    return EcampusTodoParseResult(tasks: tasks, failures: failures);
  }

  _ParsedTodoItem _parseItem(Element item) {
    final title = item.querySelector('.todo_title')?.text.trim() ?? '';
    final course = item.querySelector('.todo_subjt')?.text.trim() ?? '';
    final dDayText = item.querySelector('.todo_d_day')?.text.trim();
    final dueLabel = item.querySelector('div.todo_date span.todo_date')?.text.trim();

    final goLectureArgs = _parseGoLectureArgs(item.attributes['onclick']);
    final hiddenLectureId =
        item.querySelector('input[id^="kj_"]')?.attributes['value']?.trim();
    final hiddenType =
        item.querySelector('input[id^="gubun_"]')?.attributes['value']?.trim();

    final rawLectureId = _firstNonEmpty([
      goLectureArgs.elementAtOrNull(0),
      hiddenLectureId,
    ]);
    final rawItemId = _firstNonEmpty([goLectureArgs.elementAtOrNull(1)]);
    final rawType = _firstNonEmpty([
      goLectureArgs.elementAtOrNull(2),
      hiddenType,
    ]);

    final missingReasons = <String>[
      if (title.isEmpty) 'missing title',
      if (course.isEmpty) 'missing course',
      if (rawLectureId == null || rawItemId == null || rawType == null)
        'missing source key fields',
    ];

    if (missingReasons.isNotEmpty) {
      return _ParsedTodoItem.failure(
        EcampusParseFailure(
          reason: missingReasons.join(', '),
          rawHtml: item.outerHtml,
        ),
      );
    }

    final lectureId = rawLectureId!;
    final itemId = rawItemId!;
    final type = rawType!;

    final sourceKey = buildEcampusSourceKey(
      rawLectureId: lectureId,
      rawItemId: itemId,
      rawType: type,
    );

    return _ParsedTodoItem.task(
      ParsedEcampusTask(
        sourceKey: sourceKey,
        title: title,
        course: course,
        type: parseEcampusTaskType(type),
        dueLabel: dueLabel,
        dDay: _parseDday(dDayText),
        rawLectureId: lectureId,
        rawItemId: itemId,
        rawType: type,
      ),
    );
  }

  List<String> _parseGoLectureArgs(String? onclick) {
    if (onclick == null || onclick.trim().isEmpty) {
      return const [];
    }

    final match = RegExp(r"goLecture\s*\(([^)]*)\)").firstMatch(onclick);
    if (match == null) {
      return const [];
    }

    final argsText = match.group(1) ?? '';
    return RegExp('''['"]([^'"]*)['"]''')
        .allMatches(argsText)
        .map((match) => (match.group(1) ?? '').trim())
        .toList(growable: false);
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  int? _parseDday(String? text) {
    if (text == null) {
      return null;
    }

    final match = RegExp(r'D\s*([+-])\s*(\d+)').firstMatch(text);
    if (match == null) {
      return null;
    }

    final value = int.parse(match.group(2)!);
    return match.group(1) == '+' ? -value : value;
  }
}

EcampusTaskType parseEcampusTaskType(String rawType) {
  return switch (rawType.trim().toLowerCase()) {
    'report' => EcampusTaskType.report,
    'project' => EcampusTaskType.project,
    'lecture' => EcampusTaskType.lecture,
    'quiz' => EcampusTaskType.quiz,
    'exam' => EcampusTaskType.exam,
    _ => EcampusTaskType.unknown,
  };
}

class _ParsedTodoItem {
  const _ParsedTodoItem({this.task, this.failure});

  factory _ParsedTodoItem.task(ParsedEcampusTask task) {
    return _ParsedTodoItem(task: task);
  }

  factory _ParsedTodoItem.failure(EcampusParseFailure failure) {
    return _ParsedTodoItem(failure: failure);
  }

  final ParsedEcampusTask? task;
  final EcampusParseFailure? failure;
}

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/ecampus_models.dart';
import '../models/task_models.dart';

class EcampusTodoParser {
  const EcampusTodoParser({DateTime Function()? now}) : _now = now;

  final DateTime Function()? _now;

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
    final rawDueLabel = item
        .querySelector('div.todo_date span.todo_date')
        ?.text
        .trim();
    final dDay = _parseDday(dDayText);
    final dueDate = _parseDueDate(dueLabel: rawDueLabel, dDay: dDay);
    final dueLabel = _dueLabelFallback(rawDueLabel, dueDate);

    final goLectureArgs = _parseGoLectureArgs(item.attributes['onclick']);
    final hiddenLectureId = item
        .querySelector('input[id^="kj_"]')
        ?.attributes['value']
        ?.trim();
    final hiddenType = item
        .querySelector('input[id^="gubun_"]')
        ?.attributes['value']
        ?.trim();

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
        dueDate: dueDate,
        dueLabel: dueLabel,
        dDay: dDay,
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

  DateTime? _parseDueDate({required String? dueLabel, required int? dDay}) {
    final labelParts = _parseDueLabelParts(dueLabel);
    final now = _now?.call() ?? DateTime.now();

    DateTime? dueDay;
    if (dDay != null) {
      final today = DateTime(now.year, now.month, now.day);
      dueDay = today.add(Duration(days: dDay));
    } else if (labelParts != null) {
      dueDay = _dateFromLabel(
        now: now,
        month: labelParts.month,
        day: labelParts.day,
      );
    }

    if (dueDay == null) {
      return null;
    }

    final hour = labelParts?.hour ?? 23;
    final minute = labelParts?.minute ?? 59;
    return DateTime(dueDay.year, dueDay.month, dueDay.day, hour, minute);
  }

  _DueLabelParts? _parseDueLabelParts(String? text) {
    if (text == null) {
      return null;
    }

    final match = RegExp(
      r'(\d{1,2})\s*월\s*(\d{1,2})\s*일(?:[^\d]*(\d{1,2})\s*:\s*(\d{2}))?',
    ).firstMatch(text);
    if (match == null) {
      return null;
    }

    return _DueLabelParts(
      month: int.parse(match.group(1)!),
      day: int.parse(match.group(2)!),
      hour: match.group(3) == null ? null : int.parse(match.group(3)!),
      minute: match.group(4) == null ? null : int.parse(match.group(4)!),
    );
  }

  DateTime _dateFromLabel({
    required DateTime now,
    required int month,
    required int day,
  }) {
    final candidate = DateTime(now.year, month, day);
    final today = DateTime(now.year, now.month, now.day);
    if (candidate.difference(today).inDays < -180) {
      return DateTime(now.year + 1, month, day);
    }
    return candidate;
  }

  String? _dueLabelFallback(String? dueLabel, DateTime? dueDate) {
    if (dueLabel != null && dueLabel.trim().isNotEmpty) {
      return dueLabel;
    }
    if (dueDate == null) {
      return null;
    }
    return '${dueDate.month}월 ${dueDate.day}일';
  }
}

class _DueLabelParts {
  const _DueLabelParts({
    required this.month,
    required this.day,
    this.hour,
    this.minute,
  });

  final int month;
  final int day;
  final int? hour;
  final int? minute;
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

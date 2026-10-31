import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/ecampus_models.dart';
import '../models/task_models.dart';

class EcampusTodoParser {
  const EcampusTodoParser({DateTime Function()? now}) : _now = now;

  final DateTime Function()? _now;

  EcampusTodoParseResult parse(String html) {
    final parser = html_parser.HtmlParser(html);
    final document = parser.parse();
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

    if (tasks.isEmpty &&
        failures.isEmpty &&
        document.querySelector(
              'div.todo_wrap#no_data, div.todo_wrap.no_data',
            ) ==
            null) {
      failures.add(const EcampusParseFailure(reason: '할 일 목록 구조를 확인할 수 없습니다.'));
    }
    final seen = <String>{};
    for (final task in tasks) {
      if (!seen.add(task.sourceKey)) {
        failures.add(
          EcampusParseFailure(reason: '중복 원본 식별자: ${task.sourceKey}'),
        );
      }
    }
    // Count actual HTML parse failures, not tag-looking strings in JS/comments.
    // Empty paging shells and no_data placeholders can coexist with real items.
    final incompleteReasons = <String>[
      if (parser.errors.any(
        (error) => error.errorCode.toLowerCase().contains('eof'),
      ))
        'HTML이 태그 또는 내용 중간에서 끝났습니다',
      if (_hasMorePages(document)) '추가 페이지를 가리키는 표시가 있습니다',
    ];
    return EcampusTodoParseResult(
      tasks: tasks,
      failures: failures,
      isComplete: failures.isEmpty && incompleteReasons.isEmpty,
      incompleteReasons: incompleteReasons,
    );
  }

  bool _hasMorePages(Document document) {
    for (final element in document.querySelectorAll(
      '[data-has-more], [data-next-page], a[rel~="next"], '
      '.pagination a[href], .paging a[href]',
    )) {
      if (_isInactiveControl(element)) continue;
      if (element.attributes['data-has-more']?.trim().toLowerCase() == 'true') {
        return true;
      }
      final nextPage = element.attributes['data-next-page']
          ?.trim()
          .toLowerCase();
      if (nextPage != null &&
          !const [
            '',
            '0',
            '-1',
            'false',
            'null',
            'undefined',
          ].contains(nextPage)) {
        return true;
      }
      if (element.localName == 'a') {
        final href = element.attributes['href']?.trim().toLowerCase() ?? '';
        if (href.isNotEmpty && href != '#' && !href.startsWith('javascript:')) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isInactiveControl(Element element) {
    for (Element? node = element; node != null; node = node.parent) {
      final style = (node.attributes['style'] ?? '')
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      if (node.attributes.containsKey('hidden') ||
          node.attributes.containsKey('disabled') ||
          node.attributes['aria-hidden'] == 'true' ||
          node.attributes['aria-disabled'] == 'true' ||
          node.classes.contains('disabled') ||
          node.classes.contains('hidden') ||
          ((node == element || node.localName == 'li') &&
              (node.attributes['aria-current'] == 'page' ||
                  node.classes.contains('active') ||
                  node.classes.contains('current'))) ||
          style.contains('display:none') ||
          style.contains('visibility:hidden')) {
        return true;
      }
    }
    return false;
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

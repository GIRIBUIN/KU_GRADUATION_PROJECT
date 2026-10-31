import 'task_models.dart';

enum SyncItemKind {
  newItem,
  updateCandidate,
  alreadyImported,
  completed,
  deleted,
  excluded,
  missing,
  error,
}

enum MissingItemDecision { keep, complete, delete }

class ParsedEcampusTask {
  const ParsedEcampusTask({
    required this.sourceKey,
    required this.title,
    required this.course,
    required this.type,
    this.dueDate,
    this.dueLabel,
    this.dDay,
    this.rawLectureId,
    this.rawItemId,
    this.rawType,
  });

  final String sourceKey;
  final String title;
  final String course;
  final EcampusTaskType type;
  final DateTime? dueDate;
  final String? dueLabel;
  final int? dDay;
  final String? rawLectureId;
  final String? rawItemId;
  final String? rawType;
}

class EcampusTodoParseResult {
  const EcampusTodoParseResult({
    required this.tasks,
    required this.failures,
    this.isComplete = true,
    this.incompleteReasons = const [],
  });

  final List<ParsedEcampusTask> tasks;
  final List<EcampusParseFailure> failures;
  // A structurally incomplete/paginated response must not produce absences.
  final bool isComplete;
  final List<String> incompleteReasons;

  bool get hasFailures => failures.isNotEmpty;
}

class EcampusParseFailure {
  const EcampusParseFailure({required this.reason, this.rawHtml});

  final String reason;
  final String? rawHtml;
}

class SyncResult {
  const SyncResult({required this.items, required this.syncedAt});

  final List<SyncItem> items;
  final DateTime syncedAt;

  List<SyncItem> get missingItems =>
      items.where((item) => item.kind == SyncItemKind.missing).toList();

  List<SyncItem> get importCandidates => items
      .where(
        (item) =>
            item.kind == SyncItemKind.newItem ||
            item.kind == SyncItemKind.updateCandidate,
      )
      .toList(growable: false);

  List<SyncItem> get ignoredItems => items
      .where(
        (item) =>
            item.kind == SyncItemKind.alreadyImported ||
            item.kind == SyncItemKind.completed ||
            item.kind == SyncItemKind.deleted ||
            item.kind == SyncItemKind.excluded,
      )
      .toList(growable: false);

  List<SyncItem> get errorItems => items
      .where((item) => item.kind == SyncItemKind.error)
      .toList(growable: false);
}

class SyncItem {
  const SyncItem({
    required this.kind,
    this.parsedTask,
    this.existingTask,
    this.errorMessage,
    this.applyTitle = true,
    this.applyDueDate = true,
    this.missingDecision = MissingItemDecision.keep,
    this.targetListId,
  });

  final SyncItemKind kind;
  final ParsedEcampusTask? parsedTask;
  final Task? existingTask;
  final String? errorMessage;
  final bool applyTitle;
  final bool applyDueDate;
  final MissingItemDecision missingDecision;
  final String? targetListId;

  SyncItem withTargetList(String? listId) => SyncItem(
    kind: kind,
    parsedTask: parsedTask,
    existingTask: existingTask,
    errorMessage: errorMessage,
    applyTitle: applyTitle,
    applyDueDate: applyDueDate,
    missingDecision: missingDecision,
    targetListId: listId,
  );

  SyncItem withMissingDecision(MissingItemDecision decision) => SyncItem(
    kind: kind,
    existingTask: existingTask,
    missingDecision: decision,
  );

  SyncItem withFields({required bool title, required bool dueDate}) => SyncItem(
    kind: kind,
    parsedTask: parsedTask,
    existingTask: existingTask,
    errorMessage: errorMessage,
    applyTitle: title,
    applyDueDate: dueDate,
  );
}

String buildEcampusSourceKey({
  required String rawLectureId,
  required String rawItemId,
  required String rawType,
}) {
  return [rawLectureId.trim(), rawItemId.trim(), rawType.trim()].join(':');
}

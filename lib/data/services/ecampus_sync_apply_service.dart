import '../../core/utils/entity_id.dart';
import '../models/ecampus_models.dart';
import '../models/task_models.dart';
import '../repositories/task_repository.dart';
import '../repositories/folder_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/settings_repository.dart';

abstract class EcampusSyncApplyService {
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  });
  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  });
}

class DefaultEcampusSyncApplyService implements EcampusSyncApplyService {
  DefaultEcampusSyncApplyService({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
    required FolderRepository folderRepository,
    required SettingsRepository settingsRepository,
    DateTime Function()? now,
    String Function(ParsedEcampusTask, TaskStatus)? createId,
    this.afterTaskCommit,
    this.onPostCommitError,
  }) : _tasks = taskRepository,
       _now = now ?? DateTime.now,
       _createId = createId ?? ((parsed, status) => newEntityId());
  final TaskRepository _tasks;
  final DateTime Function() _now;
  final String Function(ParsedEcampusTask, TaskStatus) _createId;
  final Future<void> Function(Task before, Task after)? afterTaskCommit;
  final void Function(Object error)? onPostCommitError;
  Future<List<Task>> _commit(
    Iterable<SyncItem> input,
    bool exclude,
    DateTime at,
  ) async {
    final items = input
        .where(
          (item) =>
              item.kind == SyncItemKind.newItem ||
              item.kind == SyncItemKind.updateCandidate ||
              (!exclude && item.kind == SyncItemKind.missing),
        )
        .toList();
    final keys = <String>{};
    for (final item in items) {
      final key =
          (item.parsedTask?.sourceKey ?? item.existingTask?.ecampus?.sourceKey)
              ?.trim();
      if (item.kind == SyncItemKind.error ||
          key == null ||
          key.isEmpty ||
          !keys.add(key)) {
        throw StateError('유효하지 않거나 중복된 동기화 항목입니다.');
      }
    }
    final committedChanges = <(Task, Task)>[];
    Future<List<Task>> apply() async {
      final result = <Task>[];
      for (final item in items) {
        if (item.existingTask?.status == TaskStatus.completed ||
            item.existingTask?.status == TaskStatus.deleted) {
          continue;
        }
        final parsed = item.parsedTask;
        final key = parsed?.sourceKey ?? item.existingTask!.ecampus!.sourceKey;
        final current = await _tasks.getTaskByEcampusSourceKey(key);
        final expected = item.existingTask;
        if (expected != null &&
            (current == null || !_sameSnapshot(expected, current))) {
          throw StateError('미리보기 이후 일정이 변경됐습니다. 다시 조회해주세요.');
        }
        if (current?.status == TaskStatus.completed ||
            current?.status == TaskStatus.deleted) {
          continue;
        }
        if (item.kind == SyncItemKind.missing) {
          if (expected == null ||
              current == null ||
              current.origin != TaskOrigin.ecampus ||
              current.status != TaskStatus.active) {
            throw StateError('누락 검토 대상이 변경됐습니다. 다시 조회해주세요.');
          }
          switch (item.missingDecision) {
            case MissingItemDecision.keep:
              result.add(current);
            case MissingItemDecision.complete:
              final saved = await _tasks.updateTaskStatus(
                current.id,
                TaskStatus.completed,
              );
              result.add(saved);
              committedChanges.add((current, saved));
            case MissingItemDecision.delete:
              await _tasks.markDeleted(current.id);
              final saved = (await _tasks.getTaskById(current.id))!;
              result.add(saved);
              committedChanges.add((current, saved));
          }
          continue;
        }
        if (parsed == null) throw StateError('원본 항목이 없습니다.');
        if (current != null && current.status != TaskStatus.excluded) {
          if (item.kind == SyncItemKind.newItem) {
            continue; // same selection replay
          }
          final saved = await _tasks.updateTask(
            _copy(
              current,
              parsed,
              at,
              keepCurrent: exclude,
              applyTitle: item.applyTitle,
              applyDueDate: item.applyDueDate,
            ),
          );
          result.add(saved);
          if (current.dueDate != saved.dueDate) {
            committedChanges.add((current, saved));
          }
        } else {
          if (current?.status == TaskStatus.excluded && !exclude) {
            throw StateError('제외 해제 후 가져와주세요.');
          }
          result.add(
            await _tasks.createTask(
              Task(
                id: _createId(
                  parsed,
                  exclude ? TaskStatus.excluded : TaskStatus.active,
                ),
                origin: TaskOrigin.ecampus,
                status: exclude ? TaskStatus.excluded : TaskStatus.active,
                title: parsed.title,
                dueDate: parsed.dueDate,
                priority: TaskPriority.medium,
                folderIds: item.targetListId == null
                    ? const []
                    : [item.targetListId!],
                ecampus: _metadata(parsed, at),
                createdAt: at,
                updatedAt: at,
              ),
            ),
          );
        }
      }
      final backend = _tasks;
      if (backend is TransactionalTaskRepository) {
        await (backend as TransactionalTaskRepository).recordImport(
          newEntityId(),
          result.length,
          at,
        );
      }
      return result;
    }

    final backend = _tasks;
    final result = await (backend is TransactionalTaskRepository
        ? (backend as TransactionalTaskRepository).atomic(apply)
        : apply());
    // No OS calls before the entire selected batch has committed.
    for (final (before, after) in committedChanges) {
      try {
        await afterTaskCommit?.call(before, after);
      } catch (error) {
        onPostCommitError?.call(error);
      }
    }
    return result;
  }

  @override
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) => _commit(items, false, syncedAt ?? _now());
  @override
  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) => _commit(items, true, syncedAt ?? _now());
  Task _copy(
    Task t,
    ParsedEcampusTask p,
    DateTime at, {
    required bool keepCurrent,
    required bool applyTitle,
    required bool applyDueDate,
  }) => Task(
    id: t.id,
    origin: t.origin,
    status: t.status,
    title: keepCurrent || !applyTitle ? t.title : p.title,
    dueDate: keepCurrent || !applyDueDate ? t.dueDate : p.dueDate,
    priority: t.priority,
    memo: t.memo,
    tagIds: t.tagIds,
    folderIds: t.folderIds,
    sortOrder: t.sortOrder,
    ecampus: _metadata(p, at),
    createdAt: t.createdAt,
    updatedAt: at,
    completedAt: t.completedAt,
    deletedAt: t.deletedAt,
  );
  bool _sameSnapshot(Task a, Task b) =>
      a.id == b.id &&
      a.status == b.status &&
      a.title == b.title &&
      a.dueDate == b.dueDate &&
      a.memo == b.memo &&
      a.priority == b.priority &&
      a.tagIds.toSet().containsAll(b.tagIds) &&
      b.tagIds.toSet().containsAll(a.tagIds) &&
      a.folderIds.toSet().containsAll(b.folderIds) &&
      b.folderIds.toSet().containsAll(a.folderIds);
  EcampusSyncMetadata _metadata(ParsedEcampusTask p, DateTime at) =>
      EcampusSyncMetadata(
        sourceKey: p.sourceKey,
        sourceTitle: p.title,
        sourceDueDate: p.dueDate,
        sourceCourse: p.course,
        sourceType: p.type,
        lastSyncedAt: at,
      );
}

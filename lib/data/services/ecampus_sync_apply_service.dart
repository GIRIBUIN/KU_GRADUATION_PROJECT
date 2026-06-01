import '../models/ecampus_models.dart';
import '../models/task_models.dart';
import '../repositories/folder_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/task_repository.dart';

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
    String Function(ParsedEcampusTask parsedTask, TaskStatus status)? createId,
  }) : _taskRepository = taskRepository,
       _tagRepository = tagRepository,
       _folderRepository = folderRepository,
       _settingsRepository = settingsRepository,
       _now = now ?? DateTime.now,
       _createId = createId ?? _defaultCreateId;

  final TaskRepository _taskRepository;
  final TagRepository _tagRepository;
  final FolderRepository _folderRepository;
  final SettingsRepository _settingsRepository;
  final DateTime Function() _now;
  final String Function(ParsedEcampusTask parsedTask, TaskStatus status)
  _createId;

  @override
  Future<List<Task>> importItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) async {
    final appliedAt = syncedAt ?? _now();
    final appliedTasks = <Task>[];

    for (final item in items) {
      final parsedTask = item.parsedTask;
      if (parsedTask == null) {
        continue;
      }

      switch (item.kind) {
        case SyncItemKind.newItem:
          appliedTasks.add(await _createTask(parsedTask, appliedAt));
        case SyncItemKind.updateCandidate:
          final updated = await _updateTask(item, parsedTask, appliedAt);
          if (updated != null) {
            appliedTasks.add(updated);
          }
        case SyncItemKind.alreadyImported:
        case SyncItemKind.completed:
        case SyncItemKind.deleted:
        case SyncItemKind.excluded:
        case SyncItemKind.error:
          break;
      }
    }

    return appliedTasks;
  }

  @override
  Future<List<Task>> excludeItems(
    Iterable<SyncItem> items, {
    DateTime? syncedAt,
  }) async {
    final appliedAt = syncedAt ?? _now();
    final appliedTasks = <Task>[];

    for (final item in items) {
      final parsedTask = item.parsedTask;
      if (parsedTask == null || item.kind == SyncItemKind.error) {
        continue;
      }

      final existingTask = await _findExistingTask(item, parsedTask);
      if (existingTask == null) {
        appliedTasks.add(
          await _createTask(parsedTask, appliedAt, status: TaskStatus.excluded),
        );
        continue;
      }

      if (existingTask.status == TaskStatus.completed ||
          existingTask.status == TaskStatus.deleted) {
        continue;
      }

      appliedTasks.add(
        await _taskRepository.updateTask(
          await _copyTaskFromParsed(
            existingTask,
            parsedTask,
            appliedAt,
            status: TaskStatus.excluded,
          ),
        ),
      );
    }

    return appliedTasks;
  }

  Future<Task> _createTask(
    ParsedEcampusTask parsedTask,
    DateTime appliedAt, {
    TaskStatus status = TaskStatus.active,
  }) async {
    final metadata = status == TaskStatus.active
        ? await _ensureEcampusMetadata(parsedTask, appliedAt)
        : const _AutoEcampusMetadata();

    return _taskRepository.createTask(
      Task(
        id: _createId(parsedTask, status),
        origin: TaskOrigin.ecampus,
        status: status,
        title: parsedTask.title,
        dueDate: parsedTask.dueDate,
        priority: TaskPriority.medium,
        memo: parsedTask.course,
        tagIds: metadata.tag == null ? const [] : [metadata.tag!.id],
        folderIds: metadata.folder == null ? const [] : [metadata.folder!.id],
        ecampus: _metadataFromParsed(parsedTask, appliedAt),
        createdAt: appliedAt,
        updatedAt: appliedAt,
      ),
    );
  }

  Future<Task?> _updateTask(
    SyncItem item,
    ParsedEcampusTask parsedTask,
    DateTime appliedAt,
  ) async {
    final existingTask = await _findExistingTask(item, parsedTask);
    if (existingTask == null || existingTask.status != TaskStatus.active) {
      return null;
    }

    return _taskRepository.updateTask(
      await _copyTaskFromParsed(existingTask, parsedTask, appliedAt),
    );
  }

  Future<Task?> _findExistingTask(SyncItem item, ParsedEcampusTask parsedTask) {
    final existingTask = item.existingTask;
    if (existingTask != null) {
      return Future.value(existingTask);
    }

    return _taskRepository.getTaskByEcampusSourceKey(parsedTask.sourceKey);
  }

  Future<Task> _copyTaskFromParsed(
    Task existingTask,
    ParsedEcampusTask parsedTask,
    DateTime appliedAt, {
    TaskStatus? status,
  }) async {
    final shouldApplyMetadata = status == null || status == TaskStatus.active;
    final metadata = shouldApplyMetadata
        ? await _ensureEcampusMetadata(parsedTask, appliedAt)
        : const _AutoEcampusMetadata();

    return Task(
      id: existingTask.id,
      origin: existingTask.origin,
      status: status ?? existingTask.status,
      title: parsedTask.title,
      dueDate: parsedTask.dueDate,
      priority: existingTask.priority,
      memo: parsedTask.course,
      parentTaskId: existingTask.parentTaskId,
      tagIds: _appendIfMissing(existingTask.tagIds, metadata.tag?.id),
      folderIds: _appendIfMissing(existingTask.folderIds, metadata.folder?.id),
      ecampus: _metadataFromParsed(parsedTask, appliedAt),
      createdAt: existingTask.createdAt,
      updatedAt: appliedAt,
      completedAt: existingTask.completedAt,
      deletedAt: existingTask.deletedAt,
    );
  }

  Future<_AutoEcampusMetadata> _ensureEcampusMetadata(
    ParsedEcampusTask parsedTask,
    DateTime appliedAt,
  ) async {
    final folder = await _ensureEcampusFolder(appliedAt);
    final courseTag = await _ensureCourseTag(parsedTask, appliedAt);
    if (courseTag != null) {
      await _ensureTagFolder(courseTag.id, folder.id);
    }
    return _AutoEcampusMetadata(folder: folder, tag: courseTag);
  }

  Future<Folder> _ensureEcampusFolder(DateTime appliedAt) async {
    final settings = await _settingsRepository.getSettings();
    final folders = await _folderRepository.getFolders();
    final savedFolderId = settings.ecampusFolderId;
    if (savedFolderId != null) {
      final savedFolder = folders
          .where((folder) => folder.id == savedFolderId)
          .firstOrNull;
      if (savedFolder != null) {
        return savedFolder;
      }
    }

    final existingFromTasks = await _findEcampusFolderFromTasks(folders);
    if (existingFromTasks != null) {
      await _saveEcampusFolderId(settings, existingFromTasks.id);
      return existingFromTasks;
    }

    final existingByName = folders
        .where(
          (folder) =>
              folder.name == _ecampusFolderName &&
              folder.parentFolderId == null,
        )
        .firstOrNull;
    if (existingByName != null) {
      await _saveEcampusFolderId(settings, existingByName.id);
      return existingByName;
    }

    final created = await _createFolder(_ecampusFolderName, appliedAt);
    await _saveEcampusFolderId(settings, created.id);
    return created;
  }

  Future<Folder?> _findEcampusFolderFromTasks(List<Folder> folders) async {
    final folderIds = folders.map((folder) => folder.id).toSet();
    final tasks = await _taskRepository.getTasks(
      origin: TaskOrigin.ecampus,
      includeArchived: true,
    );
    for (final task in tasks) {
      for (final folderId in task.folderIds) {
        if (folderIds.contains(folderId)) {
          return folders.where((folder) => folder.id == folderId).firstOrNull;
        }
      }
    }
    return null;
  }

  Future<void> _saveEcampusFolderId(
    AppSettings settings,
    String folderId,
  ) async {
    if (settings.ecampusFolderId == folderId) {
      return;
    }
    await _settingsRepository.saveSettings(
      settings.copyWith(ecampusFolderId: folderId),
    );
  }

  Future<void> _ensureTagFolder(String tagId, String folderId) async {
    final settings = await _settingsRepository.getSettings();
    if (settings.tagFolderIds[tagId] == folderId) {
      return;
    }

    await _settingsRepository.saveSettings(
      settings.copyWith(
        tagFolderIds: {...settings.tagFolderIds, tagId: folderId},
      ),
    );
  }

  Future<Tag?> _ensureCourseTag(
    ParsedEcampusTask parsedTask,
    DateTime appliedAt,
  ) {
    final course = parsedTask.course.trim();
    if (course.isEmpty) {
      return Future.value(null);
    }
    return _ensureTag(course, appliedAt);
  }

  Future<Tag> _ensureTag(String name, DateTime appliedAt) async {
    final tags = await _tagRepository.getTags();
    final existing = tags.where((tag) => tag.name == name).firstOrNull;
    if (existing != null) {
      return existing;
    }

    return _tagRepository.createTag(
      Tag(
        id: 'tag_${appliedAt.microsecondsSinceEpoch}_${tags.length}_${_safeIdPart(name)}',
        name: name,
        color: _ecampusTagColor,
        createdAt: appliedAt,
        updatedAt: appliedAt,
      ),
    );
  }

  Future<Folder> _createFolder(String name, DateTime appliedAt) async {
    final folders = await _folderRepository.getFolders();
    return _folderRepository.createFolder(
      Folder(
        id: 'folder_${appliedAt.microsecondsSinceEpoch}_${folders.length}_${_safeIdPart(name)}',
        name: name,
        color: _ecampusFolderColor,
        icon: 'folder',
        sortOrder: await _nextRootFolderSortOrder(),
        createdAt: appliedAt,
        updatedAt: appliedAt,
      ),
    );
  }

  Future<int> _nextRootFolderSortOrder() async {
    final rootFolders = (await _folderRepository.getFolders())
        .where((folder) => folder.parentFolderId == null)
        .toList(growable: false);
    if (rootFolders.isEmpty) {
      return 0;
    }
    return rootFolders
            .map((folder) => folder.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  List<String> _appendIfMissing(List<String> values, String? value) {
    if (value == null || values.contains(value)) {
      return values;
    }
    return [...values, value];
  }

  EcampusSyncMetadata _metadataFromParsed(
    ParsedEcampusTask parsedTask,
    DateTime syncedAt,
  ) {
    return EcampusSyncMetadata(
      sourceKey: parsedTask.sourceKey,
      sourceTitle: parsedTask.title,
      sourceDueDate: parsedTask.dueDate,
      sourceCourse: parsedTask.course,
      sourceType: parsedTask.type,
      lastSyncedAt: syncedAt,
    );
  }

  static String _defaultCreateId(
    ParsedEcampusTask parsedTask,
    TaskStatus status,
  ) {
    final safeSourceKey = parsedTask.sourceKey
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final suffix = safeSourceKey.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : safeSourceKey;

    return 'ecampus_${status.name}_$suffix';
  }

  static String _safeIdPart(String value) {
    final safeValue = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9가-힣_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safeValue.isEmpty ? 'auto' : safeValue;
  }

  static const _ecampusFolderName = 'e-campus';
  static const _ecampusFolderColor = '#1262D6';
  static const _ecampusTagColor = '#3B82F6';
}

class _AutoEcampusMetadata {
  const _AutoEcampusMetadata({this.folder, this.tag});

  final Folder? folder;
  final Tag? tag;
}

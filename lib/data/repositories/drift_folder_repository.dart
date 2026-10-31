import 'package:drift/drift.dart';
import '../../core/utils/list_defaults.dart';
import '../local/app_database.dart' as db;
import '../local/mappers/metadata_mappers.dart';
import '../models/task_models.dart';
import 'folder_repository.dart';

class DriftFolderRepository implements FolderRepository, GroupedListRepository {
  const DriftFolderRepository({
    required db.AppDatabase database,
    FolderMapper mapper = const FolderMapper(),
  }) : _database = database,
       _mapper = mapper;
  final db.AppDatabase _database;
  final FolderMapper _mapper;
  @override
  Future<List<Folder>> getFolders() async =>
      (await (_database.select(_database.folders)
                ..where((t) => t.deletedAt.isNull())
                ..orderBy([
                  (t) => OrderingTerm.asc(t.sortOrder),
                  (t) => OrderingTerm.asc(t.name),
                ]))
              .get())
          .map(_mapper.fromRow)
          .toList();
  @override
  Future<Folder?> getFolderById(String id) async {
    final row = await (_database.select(
      _database.folders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.fromRow(row);
  }

  void _validate(Folder folder) {
    if (folder.parentFolderId != null) {
      throw ArgumentError('목록 안에 다른 목록을 둘 수 없습니다.');
    }
    if (folder.id == inboxListId &&
        (folder.groupId != null || folder.name != inboxListName)) {
      throw ArgumentError('미지정은 기본 목록이며 이름·소속을 변경할 수 없습니다.');
    }
  }

  Future<void> _validateGroup(Folder list) async {
    if (list.groupId == null) return;
    final group =
        await (_database.select(_database.folderGroups)
              ..where((t) => t.id.equals(list.groupId!) & t.deletedAt.isNull()))
            .getSingleOrNull();
    if (group == null) throw ArgumentError('존재하지 않거나 삭제된 상위 폴더입니다.');
  }

  @override
  Future<Folder> createFolder(Folder folder) async {
    _validate(folder);
    await _validateGroup(folder);
    final existing = await getFolders();
    final next =
        existing.fold<int>(-1, (n, f) => n > f.sortOrder ? n : f.sortOrder) + 1;
    await _database
        .into(_database.folders)
        .insert(
          _mapper
              .toCompanion(folder)
              .copyWith(
                sortOrder: Value(
                  folder.sortOrder < 0 ? next : folder.sortOrder,
                ),
              ),
        );
    return (await getFolderById(folder.id))!;
  }

  @override
  Future<Folder> updateFolder(Folder folder) async {
    _validate(folder);
    await _validateGroup(folder);
    await (_database.update(_database.folders)
          ..where((t) => t.id.equals(folder.id) & t.deletedAt.isNull()))
        .write(_mapper.toCompanion(folder));
    return (await getFolderById(folder.id))!;
  }

  @override
  Future<void> updateFolderOrder(List<String> ids) =>
      _database.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          if (ids[i] == inboxListId) continue;
          await (_database.update(
            _database.folders,
          )..where((t) => t.id.equals(ids[i]))).write(
            db.FoldersCompanion(
              sortOrder: Value(i),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      });
  @override
  Future<void> deleteFolder(String id) => _database.transaction(() async {
    if (id == inboxListId) throw ArgumentError('미지정은 보관하거나 삭제할 수 없습니다.');
    final at = DateTime.now();
    await (_database.update(_database.folders)..where((t) => t.id.equals(id)))
        .write(db.FoldersCompanion(deletedAt: Value(at), updatedAt: Value(at)));
  });

  @override
  Future<List<FolderGroup>> getGroups() async =>
      (await (_database.select(_database.folderGroups)
                ..where((t) => t.deletedAt.isNull())
                ..orderBy([
                  (t) => OrderingTerm.asc(t.sortOrder),
                  (t) => OrderingTerm.asc(t.name),
                ]))
              .get())
          .map(
            (r) => FolderGroup(
              id: r.id,
              name: r.name,
              sortOrder: r.sortOrder,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
          )
          .toList();

  @override
  Future<void> saveGroup(FolderGroup group) async {
    if (group.name.trim().isEmpty) throw ArgumentError('폴더 이름을 입력해주세요.');
    await _database
        .into(_database.folderGroups)
        .insertOnConflictUpdate(
          db.FolderGroupsCompanion.insert(
            id: group.id,
            name: group.name.trim(),
            sortOrder: Value(group.sortOrder),
            deletedAt: const Value(null),
            createdAt: group.createdAt,
            updatedAt: group.updatedAt,
          ),
        );
  }

  @override
  Future<void> deleteGroup(String id) => _database.transaction(() async {
    final at = DateTime.now();
    await (_database.update(
      _database.folders,
    )..where((t) => t.groupId.equals(id))).write(
      db.FoldersCompanion(groupId: const Value(null), updatedAt: Value(at)),
    );
    await (_database.update(
      _database.folderGroups,
    )..where((t) => t.id.equals(id))).write(
      db.FolderGroupsCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  });

  @override
  Future<List<Folder>> getArchivedLists() async =>
      (await (_database.select(
            _database.folders,
          )..where((t) => t.deletedAt.isNotNull())).get())
          .map(_mapper.fromRow)
          .toList();

  @override
  Future<void> restoreList(String id) async {
    await (_database.update(
      _database.folders,
    )..where((t) => t.id.equals(id))).write(
      db.FoldersCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> moveList(
    String listId,
    String? groupId, {
    String? beforeListId,
  }) => _database.transaction(() async {
    if (listId == inboxListId) throw ArgumentError('미지정은 고정 목록입니다.');
    final current = await getFolderById(listId);
    if (current == null || current.archivedAt != null) {
      throw StateError('이동할 목록을 찾을 수 없습니다.');
    }
    if (beforeListId != null) {
      final target = await getFolderById(beforeListId);
      if (target == null ||
          target.archivedAt != null ||
          target.groupId != groupId ||
          target.id == inboxListId ||
          target.id == listId) {
        throw StateError('이동 위치가 변경됐습니다. 다시 시도해주세요.');
      }
    }
    await updateFolder(
      Folder(
        id: current.id,
        name: current.name,
        color: current.color,
        icon: current.icon,
        groupId: groupId,
        sortOrder: current.sortOrder,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
    if (beforeListId != null) {
      final ids =
          (await getFolders())
              .where((list) => list.groupId == groupId)
              .map((list) => list.id)
              .toList()
            ..remove(listId);
      ids.insert(ids.indexOf(beforeListId), listId);
      await updateFolderOrder(ids);
    }
  });
}

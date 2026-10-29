import 'package:drift/drift.dart';
import '../local/app_database.dart' as db;
import '../local/mappers/metadata_mappers.dart';
import '../models/task_models.dart';
import 'folder_repository.dart';

class DriftFolderRepository implements FolderRepository {
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
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : _mapper.fromRow(row);
  }

  void _validate(Folder folder) {
    if (folder.parentFolderId != null) throw ArgumentError('폴더는 한 단계만 지원합니다.');
  }

  @override
  Future<Folder> createFolder(Folder folder) async {
    _validate(folder);
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
    await (_database.update(_database.folders)
          ..where((t) => t.id.equals(folder.id) & t.deletedAt.isNull()))
        .write(_mapper.toCompanion(folder));
    return (await getFolderById(folder.id))!;
  }

  @override
  Future<void> updateFolderOrder(List<String> ids) =>
      _database.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
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
    final at = DateTime.now();
    await (_database.update(
      _database.tasks,
    )..where((t) => t.folderId.equals(id))).write(
      db.TasksCompanion(folderId: const Value(null), updatedAt: Value(at)),
    );
    await (_database.update(_database.folders)..where((t) => t.id.equals(id)))
        .write(db.FoldersCompanion(deletedAt: Value(at), updatedAt: Value(at)));
  });
}

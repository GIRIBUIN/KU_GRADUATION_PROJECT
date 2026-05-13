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
  Future<List<Folder>> getFolders() async {
    final rows =
        await (_database.select(_database.folders)..orderBy([
              (table) => OrderingTerm(expression: table.parentFolderId),
              (table) => OrderingTerm(expression: table.sortOrder),
              (table) => OrderingTerm(expression: table.name),
            ]))
            .get();
    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<Folder?> getFolderById(String id) async {
    final row = await (_database.select(
      _database.folders,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<Folder> createFolder(Folder folder) async {
    final folderToCreate = folder.sortOrder < 0
        ? _copyFolderWithSortOrder(
            folder,
            await _nextSortOrder(folder.parentFolderId),
          )
        : folder;
    await _database
        .into(_database.folders)
        .insert(_mapper.toCompanion(folderToCreate));
    return (await getFolderById(folder.id))!;
  }

  @override
  Future<Folder> updateFolder(Folder folder) async {
    await (_database.update(_database.folders)
          ..where((table) => table.id.equals(folder.id)))
        .write(_mapper.toCompanion(folder));
    return (await getFolderById(folder.id))!;
  }

  @override
  Future<void> updateFolderOrder(List<String> folderIds) async {
    await _database.transaction(() async {
      for (var index = 0; index < folderIds.length; index++) {
        await (_database.update(_database.folders)
              ..where((table) => table.id.equals(folderIds[index])))
            .write(db.FoldersCompanion(sortOrder: Value(index)));
      }
    });
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.taskFolders,
      )..where((table) => table.folderId.equals(id))).go();
      await (_database.delete(
        _database.folders,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<int> _nextSortOrder(String? parentFolderId) async {
    final query = _database.select(_database.folders)
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.sortOrder, mode: OrderingMode.desc),
      ])
      ..limit(1);
    if (parentFolderId == null) {
      query.where((table) => table.parentFolderId.isNull());
    } else {
      query.where((table) => table.parentFolderId.equals(parentFolderId));
    }
    final rows = await query.get();
    if (rows.isEmpty) {
      return 0;
    }
    return rows.first.sortOrder + 1;
  }

  Folder _copyFolderWithSortOrder(Folder folder, int sortOrder) {
    return Folder(
      id: folder.id,
      name: folder.name,
      color: folder.color,
      icon: folder.icon,
      parentFolderId: folder.parentFolderId,
      sortOrder: sortOrder,
      createdAt: folder.createdAt,
      updatedAt: folder.updatedAt,
    );
  }
}

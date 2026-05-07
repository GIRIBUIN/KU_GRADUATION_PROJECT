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
    final rows = await (_database.select(
      _database.folders,
    )..orderBy([(table) => OrderingTerm(expression: table.name)])).get();
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
    await _database.into(_database.folders).insert(_mapper.toCompanion(folder));
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
}

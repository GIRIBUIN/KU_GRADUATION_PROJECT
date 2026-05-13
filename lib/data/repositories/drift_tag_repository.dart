import 'package:drift/drift.dart';

import '../local/app_database.dart' as db;
import '../local/mappers/metadata_mappers.dart';
import '../models/task_models.dart';
import 'tag_repository.dart';

class DriftTagRepository implements TagRepository {
  const DriftTagRepository({
    required db.AppDatabase database,
    TagMapper mapper = const TagMapper(),
  }) : _database = database,
       _mapper = mapper;

  final db.AppDatabase _database;
  final TagMapper _mapper;

  @override
  Future<List<Tag>> getTags() async {
    final rows = await (_database.select(
      _database.tags,
    )..orderBy([(table) => OrderingTerm(expression: table.name)])).get();
    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<Tag?> getTagById(String id) async {
    final row = await (_database.select(
      _database.tags,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<Tag> createTag(Tag tag) async {
    await _database.into(_database.tags).insert(_mapper.toCompanion(tag));
    return (await getTagById(tag.id))!;
  }

  @override
  Future<Tag> updateTag(Tag tag) async {
    await (_database.update(_database.tags)
          ..where((table) => table.id.equals(tag.id)))
        .write(_mapper.toCompanion(tag));
    return (await getTagById(tag.id))!;
  }

  @override
  Future<void> deleteTag(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.taskTags,
      )..where((table) => table.tagId.equals(id))).go();
      await (_database.delete(
        _database.tags,
      )..where((table) => table.id.equals(id))).go();
    });
  }
}

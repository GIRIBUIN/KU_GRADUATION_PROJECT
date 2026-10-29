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
  Future<List<Tag>> getTags() async =>
      (await (_database.select(_database.tags)
                ..where((t) => t.deletedAt.isNull())
                ..orderBy([
                  (t) => OrderingTerm.asc(t.sortOrder),
                  (t) => OrderingTerm.asc(t.name),
                ]))
              .get())
          .map(_mapper.fromRow)
          .toList();
  @override
  Future<Tag?> getTagById(String id) async {
    final row = await (_database.select(
      _database.tags,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
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
          ..where((t) => t.id.equals(tag.id) & t.deletedAt.isNull()))
        .write(_mapper.toCompanion(tag));
    return (await getTagById(tag.id))!;
  }

  @override
  Future<void> deleteTag(String id) => _database.transaction(() async {
    final at = DateTime.now();
    await (_database.update(
      _database.taskTags,
    )..where((t) => t.tagId.equals(id))).write(
      db.TaskTagsCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
    await (_database.update(_database.ecampusCourses)
          ..where((t) => t.tagId.equals(id)))
        .write(const db.EcampusCoursesCompanion(tagId: Value(null)));
    await (_database.update(_database.tags)..where((t) => t.id.equals(id)))
        .write(db.TagsCompanion(deletedAt: Value(at), updatedAt: Value(at)));
  });
}

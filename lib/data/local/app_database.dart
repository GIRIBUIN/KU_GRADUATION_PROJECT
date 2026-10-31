import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../../core/utils/entity_id.dart';
import '../../core/utils/list_defaults.dart';
part 'app_database.g.dart';
part 'schema_v6_migration.dart';
part 'schema_v7_migration.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get priority => text().nullable()();
  TextColumn get memo => text().nullable()();
  // Legacy Dart accessor; physically a required list_id, never a group ID.
  TextColumn get folderId => text()
      .named('list_id')
      .withDefault(const Constant(inboxListId))
      .references(Folders, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    "CHECK (priority IS NULL OR priority IN ('high','medium','low'))",
  ];
}

class SubTasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get title => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Folders extends Table {
  // Keep the repository adapter's Dart name while giving storage its real role.
  @override
  String get tableName => 'task_lists';
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get groupId =>
      text().named('folder_id').nullable().references(FolderGroups, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    "CHECK (id <> 'kutodo:inbox' OR (folder_id IS NULL AND deleted_at IS NULL))",
  ];
}

class FolderGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

class EcampusCourses extends Table {
  TextColumn get id => text()();
  TextColumn get sourceScopeId => text()();
  TextColumn get externalCourseKey => text().nullable()();
  TextColumn get name => text()();
  TextColumn get tagId => text().nullable().references(Tags, #id)();
  TextColumn get listId => text().nullable().references(Folders, #id)();
  DateTimeColumn get lastObservedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceScopeId, externalCourseKey},
  ];
}

class EcampusItems extends Table {
  TextColumn get id => text()();
  TextColumn get sourceScopeId => text()();
  TextColumn get courseId =>
      text().nullable().references(EcampusCourses, #id)();
  TextColumn get externalKey => text().nullable()();
  TextColumn get sourceTitle => text()();
  TextColumn get sourceCourse => text().nullable()();
  TextColumn get sourceType => text().nullable()();
  DateTimeColumn get sourceStartAt => dateTime().nullable()();
  DateTimeColumn get sourceEndAt => dateTime().nullable()();
  TextColumn get taskId => text().nullable().unique().references(Tasks, #id)();
  TextColumn get importState => text()();
  DateTimeColumn get firstObservedAt => dateTime()();
  DateTimeColumn get lastObservedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceScopeId, externalKey},
  ];
  @override
  List<String> get customConstraints => [
    "CHECK ((import_state = 'imported' AND task_id IS NOT NULL) OR (import_state IN ('ignored','unreviewed') AND task_id IS NULL))",
  ];
}

class ImportSessions extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text().withDefault(const Constant('ecampus'))();
  TextColumn get inputMethod =>
      text().withDefault(const Constant('webview_html'))();
  TextColumn get sourceScopeId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get state => text()();
  IntColumn get appliedCount => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class TaskReminders extends Table {
  TextColumn get id => text().unique()();
  TextColumn get taskId => text().references(Tasks, #id)();
  BoolColumn get enabled => boolean()();
  IntColumn get offsetMinutes => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {taskId};
  @override
  List<String> get customConstraints => ['CHECK (offset_minutes >= 0)'];
}

class LocalNotificationSchedules extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  IntColumn get platformNotificationId => integer().nullable().unique()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column> get primaryKey => {taskId};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {key};
}

class MigrationIssues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityId => text()();
  TextColumn get reason => text()();
  TextColumn get legacyData => text()();
}

class DeletedEntities extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  DateTimeColumn get deletedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

@DriftDatabase(
  tables: [
    Tasks,
    SubTasks,
    Tags,
    Folders,
    FolderGroups,
    TaskTags,
    EcampusCourses,
    EcampusItems,
    ImportSessions,
    TaskReminders,
    LocalNotificationSchedules,
    AppSettings,
    MigrationIssues,
    DeletedEntities,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.defaults() : super(driftDatabase(name: 'ku_task_management'));
  // Single local dataset, not a verified LMS account or cloud identity.
  static const defaultSourceScope = 'legacy-local';
  @override
  int get schemaVersion => 7;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _ensureInbox();
    },
    onUpgrade: (migrator, from, to) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(() async {
        if (from < 2) {
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (from < 3) {
          await customStatement(
            'ALTER TABLE folders ADD COLUMN parent_folder_id TEXT REFERENCES folders(id)',
          );
        }
        if (from < 4) {
          await customStatement(
            'CREATE TABLE tags_new (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, color TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
          );
          await customStatement(
            'INSERT INTO tags_new SELECT id, name, color, created_at, updated_at FROM tags',
          );
          await customStatement('DROP TABLE tags');
          await customStatement('ALTER TABLE tags_new RENAME TO tags');
        }
        if (from < 5) {
          await customStatement(
            'ALTER TABLE folders ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (from < 6) {
          await _migrateV5(migrator);
        } else if (from < 7) {
          await _migrateV6(migrator);
        }
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      for (final sql in [
        'CREATE INDEX IF NOT EXISTS tasks_active_order ON tasks(deleted_at, completed_at, sort_order, created_at)',
        'CREATE INDEX IF NOT EXISTS tasks_list ON tasks(list_id)',
        'CREATE INDEX IF NOT EXISTS lists_folder ON task_lists(folder_id, deleted_at, sort_order)',
        'CREATE INDEX IF NOT EXISTS tasks_due ON tasks(due_date)',
        'CREATE INDEX IF NOT EXISTS subtasks_parent ON sub_tasks(task_id, deleted_at, position)',
        'CREATE INDEX IF NOT EXISTS task_tags_tag ON task_tags(tag_id, deleted_at)',
      ]) {
        await customStatement(sql);
      }
    },
  );
}

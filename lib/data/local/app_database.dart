import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get origin => text()();
  TextColumn get status => text()();
  TextColumn get title => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get priority => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get parentTaskId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get ecampusSourceKey => text().nullable().unique()();
  TextColumn get ecampusSourceTitle => text().nullable()();
  DateTimeColumn get ecampusSourceDueDate => dateTime().nullable()();
  TextColumn get ecampusSourceCourse => text().nullable()();
  TextColumn get ecampusSourceType => text().nullable()();
  DateTimeColumn get ecampusLastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SubTasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get defaultPriority => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column<Object>> get primaryKey => {taskId, tagId};
}

class TaskFolders extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get folderId => text().references(Folders, #id)();

  @override
  Set<Column<Object>> get primaryKey => {taskId, folderId};
}

class NotificationSettings extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  BoolColumn get enabled => boolean()();
  IntColumn get daysBeforeDue => integer()();
  TextColumn get notifyTime => text()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Tasks,
    SubTasks,
    Tags,
    Folders,
    TaskTags,
    TaskFolders,
    NotificationSettings,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'ku_task_management'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(tasks, tasks.sortOrder);
      }
    },
  );
}

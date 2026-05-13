import 'package:drift/drift.dart';

import '../local/app_database.dart' as db;
import '../local/mappers/metadata_mappers.dart';
import '../models/task_models.dart';
import 'notification_repository.dart';

class DriftNotificationRepository implements NotificationRepository {
  const DriftNotificationRepository({
    required db.AppDatabase database,
    NotificationSettingMapper mapper = const NotificationSettingMapper(),
  }) : _database = database,
       _mapper = mapper;

  final db.AppDatabase _database;
  final NotificationSettingMapper _mapper;

  @override
  Future<NotificationSetting?> getByTaskId(String taskId) async {
    final row = await (_database.select(
      _database.notificationSettings,
    )..where((table) => table.taskId.equals(taskId))).getSingleOrNull();
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<List<NotificationSetting>> getAll() async {
    final query = _database.select(_database.notificationSettings)
      ..orderBy([(table) => OrderingTerm(expression: table.taskId)]);
    final rows = await query.get();
    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<NotificationSetting> save(NotificationSetting notification) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.notificationSettings,
      )..where((table) => table.taskId.equals(notification.taskId))).go();
      await _database
          .into(_database.notificationSettings)
          .insert(_mapper.toCompanion(notification));
    });

    return (await getByTaskId(notification.taskId))!;
  }

  @override
  Future<void> deleteByTaskId(String taskId) async {
    await (_database.delete(
      _database.notificationSettings,
    )..where((table) => table.taskId.equals(taskId))).go();
  }
}

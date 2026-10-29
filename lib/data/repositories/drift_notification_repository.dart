import 'package:drift/drift.dart';
import '../local/app_database.dart' as db;
import '../local/mappers/metadata_mappers.dart';
import '../models/task_models.dart';
import 'notification_repository.dart';

class DriftNotificationRepository
    implements NotificationRepository, LocalNotificationStateStore {
  const DriftNotificationRepository({
    required db.AppDatabase database,
    NotificationSettingMapper mapper = const NotificationSettingMapper(),
  }) : _database = database,
       _mapper = mapper;
  final db.AppDatabase _database;
  final NotificationSettingMapper _mapper;

  @override
  Future<int> notificationId(String taskId, int preferred) =>
      _database.transaction(() async {
        final current = await (_database.select(
          _database.localNotificationSchedules,
        )..where((t) => t.taskId.equals(taskId))).getSingleOrNull();
        if (current?.platformNotificationId != null) {
          return current!.platformNotificationId!;
        }
        final task = await (_database.select(
          _database.tasks,
        )..where((t) => t.id.equals(taskId))).getSingleOrNull();
        if (task == null) return preferred;
        final used =
            (await _database.select(_database.localNotificationSchedules).get())
                .map((r) => r.platformNotificationId)
                .whereType<int>()
                .toSet();
        var id = preferred;
        while (used.contains(id)) {
          id = id == 0x7fffffff ? 1 : id + 1;
        }
        await _database
            .into(_database.localNotificationSchedules)
            .insertOnConflictUpdate(
              db.LocalNotificationSchedulesCompanion.insert(
                taskId: taskId,
                platformNotificationId: Value(id),
              ),
            );
        return id;
      });

  @override
  Future<void> recordSchedule(
    String taskId,
    DateTime? scheduledAt, {
    String? error,
  }) async {
    await (_database.update(
      _database.localNotificationSchedules,
    )..where((t) => t.taskId.equals(taskId))).write(
      db.LocalNotificationSchedulesCompanion(
        scheduledAt: Value(scheduledAt),
        lastError: Value(error),
      ),
    );
  }

  @override
  Future<NotificationSetting?> getByTaskId(String id) async {
    final row = await (_database.select(
      _database.taskReminders,
    )..where((t) => t.taskId.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final local = await (_database.select(
      _database.localNotificationSchedules,
    )..where((t) => t.taskId.equals(id))).getSingleOrNull();
    return _mapper.fromRow(row, scheduledAt: local?.scheduledAt);
  }

  @override
  Future<List<NotificationSetting>> getAll() async {
    final rows = await (_database.select(
      _database.taskReminders,
    )..orderBy([(t) => OrderingTerm.asc(t.taskId)])).get();
    final local = {
      for (final r
          in await _database.select(_database.localNotificationSchedules).get())
        r.taskId: r.scheduledAt,
    };
    return rows
        .map((r) => _mapper.fromRow(r, scheduledAt: local[r.taskId]))
        .toList();
  }

  @override
  Future<NotificationSetting> save(NotificationSetting setting) =>
      _database.transaction(() async {
        if (setting.daysBeforeDue < 0) throw ArgumentError('알림은 0분 이상이어야 합니다.');
        await _database
            .into(_database.taskReminders)
            .insertOnConflictUpdate(_mapper.toCompanion(setting));
        if (setting.scheduledAt != null) {
          await _database
              .into(_database.localNotificationSchedules)
              .insertOnConflictUpdate(
                db.LocalNotificationSchedulesCompanion.insert(
                  taskId: setting.taskId,
                  scheduledAt: Value(setting.scheduledAt),
                ),
              );
        }
        return (await getByTaskId(setting.taskId))!;
      });
  @override
  Future<void> deleteByTaskId(String id) => _database.transaction(() async {
    await (_database.delete(
      _database.localNotificationSchedules,
    )..where((t) => t.taskId.equals(id))).go();
    await (_database.delete(
      _database.taskReminders,
    )..where((t) => t.taskId.equals(id))).go();
  });
}

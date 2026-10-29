import 'package:drift/drift.dart';
import '../local/app_database.dart' as db;
import '../local/mappers/metadata_mappers.dart';
import 'settings_repository.dart';

class DriftSettingsRepository implements SettingsRepository {
  const DriftSettingsRepository({
    required db.AppDatabase database,
    AppSettingsMapper mapper = const AppSettingsMapper(),
  }) : _database = database,
       _mapper = mapper;

  final db.AppDatabase _database;
  final AppSettingsMapper _mapper;

  @override
  Future<AppSettings> getSettings() async {
    final rows = await _database.select(_database.appSettings).get();
    final tags = await _database.select(_database.tags).get();
    return _mapper
        .fromMap({for (final row in rows) row.key: row.value})
        .copyWith(
          tagFolderIds: const {},
          tagSortOrders: {
            for (final tag in tags)
              if (tag.deletedAt == null) tag.id: tag.sortOrder,
          },
        );
  }

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    final values = _mapper.toMap(settings);
    final now = DateTime.now();

    await _database.transaction(() async {
      await _database
          .update(_database.tags)
          .write(db.TagsCompanion(sortOrder: const Value(0)));
      for (final entry in settings.tagSortOrders.entries) {
        await (_database.update(
          _database.tags,
        )..where((t) => t.id.equals(entry.key))).write(
          db.TagsCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(now),
          ),
        );
      }
      for (final entry in values.entries) {
        if (['tagFolderIds', 'tagSortOrders'].contains(entry.key)) continue;
        await _database
            .into(_database.appSettings)
            .insertOnConflictUpdate(
              db.AppSettingsCompanion.insert(
                key: entry.key,
                value: entry.value,
                updatedAt: now,
              ),
            );
      }
    });

    return getSettings();
  }
}

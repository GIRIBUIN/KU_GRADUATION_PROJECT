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
    return _mapper.fromMap({for (final row in rows) row.key: row.value});
  }

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    final values = _mapper.toMap(settings);
    final now = DateTime.now();

    await _database.transaction(() async {
      for (final entry in values.entries) {
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

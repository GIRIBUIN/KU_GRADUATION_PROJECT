import '../local/app_database.dart';
import '../repositories/drift_settings_repository.dart';
import '../repositories/drift_folder_repository.dart';
import '../repositories/drift_task_repository.dart';
import 'widget_update_service.dart';

/// UI 없이 일반 앱과 동일한 DB·선택·정렬·재시도 로직으로 두 위젯을 갱신한다.
Future<void> refreshWidgetsInBackground({
  DateTime Function()? now,
  AppDatabase Function()? openDatabase,
}) async {
  final database = (openDatabase ?? AppDatabase.defaults)();
  try {
    await WidgetUpdateService(
      taskRepository: DriftTaskRepository(database: database),
      settingsRepository: DriftSettingsRepository(database: database),
      folderRepository: DriftFolderRepository(database: database),
      now: now,
    ).refresh();
  } finally {
    await database.close();
  }
}

import '../models/ecampus_models.dart';
import '../models/task_models.dart';
import 'ecampus_auth_service.dart';

abstract class EcampusSyncService {
  Future<SyncResult> previewSync({
    required EcampusSession session,
    required List<Task> existingTasks,
    DateTime? syncedAt,
  });
}

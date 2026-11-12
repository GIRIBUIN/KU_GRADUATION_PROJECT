import '../local/app_database.dart' show AppDatabase;
import '../models/task_models.dart';
import '../repositories/tag_repository.dart';
import '../repositories/task_repository.dart';

/// 기존 Repository로 새 태그와 일정을 한 번에 저장한다.
class WidgetTaskCreationService {
  const WidgetTaskCreationService({
    required this.database,
    required this.taskRepository,
    required this.tagRepository,
  });

  final AppDatabase database;
  final TaskRepository taskRepository;
  final TagRepository tagRepository;

  Future<void> save(Task task, List<Tag> newTags) {
    // 일정 저장까지 모두 성공해야 확정하며, 실패하면 생성한 태그도 함께 되돌린다.
    return database.transaction(() async {
      for (final tag in newTags) {
        await tagRepository.createTag(tag);
      }
      await taskRepository.createTask(task);
    });
  }
}

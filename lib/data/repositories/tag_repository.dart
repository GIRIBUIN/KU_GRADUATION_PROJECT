import '../models/task_models.dart';

abstract class TagRepository {
  Future<List<Tag>> getTags();

  Future<Tag?> getTagById(String id);

  Future<Tag> createTag(Tag tag);

  Future<Tag> updateTag(Tag tag);

  Future<void> deleteTag(String id);
}

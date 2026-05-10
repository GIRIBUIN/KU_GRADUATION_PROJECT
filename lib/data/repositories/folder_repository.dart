import '../models/task_models.dart';

abstract class FolderRepository {
  Future<List<Folder>> getFolders();

  Future<Folder?> getFolderById(String id);

  Future<Folder> createFolder(Folder folder);

  Future<Folder> updateFolder(Folder folder);

  Future<void> updateFolderOrder(List<String> folderIds);

  Future<void> deleteFolder(String id);
}

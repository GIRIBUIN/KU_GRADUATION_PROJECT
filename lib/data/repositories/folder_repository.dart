import '../models/task_models.dart';

abstract class FolderRepository {
  Future<List<Folder>> getFolders();

  Future<Folder?> getFolderById(String id);

  Future<Folder> createFolder(Folder folder);

  Future<Folder> updateFolder(Folder folder);

  Future<void> updateFolderOrder(List<String> folderIds);

  Future<void> deleteFolder(String id);
}

/// Additional list-grouping capabilities, without changing existing adapters.
abstract interface class GroupedListRepository {
  Future<List<FolderGroup>> getGroups();
  Future<void> saveGroup(FolderGroup group);
  Future<void> deleteGroup(String id);
  Future<List<Folder>> getArchivedLists();
  Future<void> restoreList(String id);
  Future<void> moveList(String listId, String? groupId, {String? beforeListId});
}

import '../models/ecampus_models.dart';

abstract class EcampusSyncService {
  Future<SyncResult> previewSync();

  Future<void> importSelected(List<SyncItem> items);

  Future<void> excludeSelected(List<SyncItem> items);
}

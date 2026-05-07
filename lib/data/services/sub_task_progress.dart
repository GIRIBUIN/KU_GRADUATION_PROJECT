import '../models/task_models.dart';

class SubTaskProgress {
  const SubTaskProgress({
    required this.totalCount,
    required this.doneCount,
  });

  final int totalCount;
  final int doneCount;

  bool get hasSubTasks => totalCount > 0;

  double get ratio => totalCount == 0 ? 0 : doneCount / totalCount;

  int get percent => (ratio * 100).round();
}

SubTaskProgress calculateSubTaskProgress(Iterable<SubTask> subTasks) {
  final items = subTasks.toList(growable: false);
  return SubTaskProgress(
    totalCount: items.length,
    doneCount: items.where((subTask) => subTask.isDone).length,
  );
}

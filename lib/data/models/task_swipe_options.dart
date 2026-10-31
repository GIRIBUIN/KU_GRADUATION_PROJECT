import 'dart:convert';

enum TaskSwipeAction {
  complete('완료 / 해제'),
  edit('편집'),
  delete('삭제'),
  restore('복원'),
  deletePermanently('영구 삭제');

  const TaskSwipeAction(this.label);
  final String label;
}

const normalSwipeActions = [
  TaskSwipeAction.complete,
  TaskSwipeAction.edit,
  TaskSwipeAction.delete,
];
const trashSwipeActions = [
  TaskSwipeAction.restore,
  TaskSwipeAction.deletePermanently,
];

class TaskSwipeOptions {
  const TaskSwipeOptions({
    this.right = TaskSwipeAction.complete,
    this.left = TaskSwipeAction.delete,
    this.trashRight = TaskSwipeAction.restore,
    this.trashLeft = TaskSwipeAction.deletePermanently,
  });

  final TaskSwipeAction right, left, trashRight, trashLeft;

  TaskSwipeAction action({required bool toRight, required bool inTrash}) =>
      inTrash ? (toRight ? trashRight : trashLeft) : (toRight ? right : left);

  TaskSwipeOptions copyWith({
    TaskSwipeAction? right,
    TaskSwipeAction? left,
    TaskSwipeAction? trashRight,
    TaskSwipeAction? trashLeft,
  }) => TaskSwipeOptions(
    right: right ?? this.right,
    left: left ?? this.left,
    trashRight: trashRight ?? this.trashRight,
    trashLeft: trashLeft ?? this.trashLeft,
  );

  String encode() => jsonEncode({
    'right': right.name,
    'left': left.name,
    'trashRight': trashRight.name,
    'trashLeft': trashLeft.name,
  });

  static TaskSwipeOptions decode(String? raw) {
    const defaults = TaskSwipeOptions();
    try {
      final value = jsonDecode(raw ?? 'null');
      if (value is! Map) return defaults;
      TaskSwipeAction read(
        String key,
        List<TaskSwipeAction> allowed,
        TaskSwipeAction fallback,
      ) => allowed.where((a) => a.name == value[key]).firstOrNull ?? fallback;
      return TaskSwipeOptions(
        right: read('right', normalSwipeActions, defaults.right),
        left: read('left', normalSwipeActions, defaults.left),
        trashRight: read('trashRight', trashSwipeActions, defaults.trashRight),
        trashLeft: read('trashLeft', trashSwipeActions, defaults.trashLeft),
      );
    } catch (_) {
      return defaults;
    }
  }
}

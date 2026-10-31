import 'dart:convert';
import 'task_models.dart';

enum HomeSort {
  standard('기본'),
  dueSoon('마감 빠른 순'),
  dueLate('마감 늦은 순'),
  newest('최근 생성 순'),
  priority('우선순위');

  const HomeSort(this.label);
  final String label;
}

/// Sort and filter preferences; the date selection is saved separately.
class HomeViewOptions {
  const HomeViewOptions({
    this.sort = HomeSort.standard,
    this.statuses = const {TaskStatus.active, TaskStatus.completed},
    this.priorities = const {},
    this.tagIds = const {},
  });

  final HomeSort sort;
  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;
  final Set<String> tagIds;

  bool get isDefault =>
      sort == HomeSort.standard &&
      statuses.length == 2 &&
      statuses.contains(TaskStatus.active) &&
      statuses.contains(TaskStatus.completed) &&
      priorities.isEmpty &&
      tagIds.isEmpty;

  HomeViewOptions copyWith({
    HomeSort? sort,
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    Set<String>? tagIds,
  }) => HomeViewOptions(
    sort: sort ?? this.sort,
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    tagIds: tagIds ?? this.tagIds,
  );

  String encode() => jsonEncode({
    'sort': sort.name,
    'statuses': statuses.map((s) => s.name).toList(),
    'priorities': priorities.map((p) => p.name).toList(),
    'tags': tagIds.toList(),
  });

  static HomeViewOptions decode(String? raw) {
    try {
      final value = jsonDecode(raw ?? 'null');
      if (value is! Map) return const HomeViewOptions();
      Set<T> choices<T extends Enum>(
        String key,
        List<T> values,
        Set<T> fallback,
      ) {
        final saved = value[key];
        return saved is List
            ? values.where((v) => saved.contains(v.name)).toSet()
            : fallback;
      }

      return HomeViewOptions(
        sort:
            HomeSort.values.where((s) => s.name == value['sort']).firstOrNull ??
            HomeSort.standard,
        statuses: choices(
          'statuses',
          [TaskStatus.active, TaskStatus.completed],
          const {TaskStatus.active, TaskStatus.completed},
        ),
        priorities: choices('priorities', TaskPriority.values, const {}),
        tagIds: value['tags'] is List
            ? (value['tags'] as List).whereType<String>().toSet()
            : const {},
      );
    } on FormatException {
      return const HomeViewOptions();
    }
  }
}

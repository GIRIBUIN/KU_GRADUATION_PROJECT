import 'dart:convert';

class WeeklyWidgetTaskSnapshot {
  const WeeklyWidgetTaskSnapshot({
    required this.id,
    required this.title,
    required this.categoryLabel,
    required this.categoryBackgroundHex,
    required this.categoryTextHex,
    required this.dueLabel,
    required this.dueColorHex,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String categoryLabel;
  final String categoryBackgroundHex;
  final String categoryTextHex;
  final String dueLabel;
  final String dueColorHex;
  final bool isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'categoryLabel': categoryLabel,
      'categoryBackgroundHex': categoryBackgroundHex,
      'categoryTextHex': categoryTextHex,
      'dueLabel': dueLabel,
      'dueColorHex': dueColorHex,
      'isCompleted': isCompleted,
    };
  }

  factory WeeklyWidgetTaskSnapshot.fromJson(Map<String, dynamic> json) {
    return WeeklyWidgetTaskSnapshot(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryLabel: json['categoryLabel'] as String? ?? '개인',
      categoryBackgroundHex:
          json['categoryBackgroundHex'] as String? ?? '#FCE7F3',
      categoryTextHex: json['categoryTextHex'] as String? ?? '#DB2777',
      dueLabel: json['dueLabel'] as String? ?? 'D-day',
      dueColorHex: json['dueColorHex'] as String? ?? '#1262D6',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class WeeklyWidgetData {
  const WeeklyWidgetData({
    required this.weekRangeLabel,
    required this.completedCount,
    required this.totalCount,
    required this.tasks,
    required this.updatedAt,
  });

  static const maxTasks = 5;
  /// WeeklyScheduleWidgetProvider와 공유하는 home_widget 키.
  static const storageKey = 'weekly_schedule_widget_data';

  final String weekRangeLabel;
  final int completedCount;
  final int totalCount;
  final List<WeeklyWidgetTaskSnapshot> tasks;
  final DateTime updatedAt;

  /// completedCount / totalCount → ProgressBar(0~100).
  int get progressPercent {
    if (totalCount <= 0) {
      return 0;
    }
    return ((completedCount / totalCount) * 100).round().clamp(0, 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'weekRangeLabel': weekRangeLabel,
      'completedCount': completedCount,
      'totalCount': totalCount,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory WeeklyWidgetData.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'];
    return WeeklyWidgetData(
      weekRangeLabel: json['weekRangeLabel'] as String? ?? '',
      completedCount: json['completedCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      tasks: tasksJson is List
          ? tasksJson
                .whereType<Map<String, dynamic>>()
                .map(WeeklyWidgetTaskSnapshot.fromJson)
                .toList(growable: false)
          : const [],
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

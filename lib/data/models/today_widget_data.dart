import 'dart:convert';

class TodayWidgetTaskSnapshot {
  const TodayWidgetTaskSnapshot({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.accentColorHex,
  });

  final String id;
  final String title;
  final String timeLabel;
  final String accentColorHex;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timeLabel': timeLabel,
      'accentColorHex': accentColorHex,
    };
  }

  factory TodayWidgetTaskSnapshot.fromJson(Map<String, dynamic> json) {
    return TodayWidgetTaskSnapshot(
      id: json['id'] as String,
      title: json['title'] as String,
      timeLabel: json['timeLabel'] as String? ?? '--:--',
      accentColorHex: json['accentColorHex'] as String? ?? '#1262D6',
    );
  }
}

class TodayWidgetData {
  const TodayWidgetData({
    required this.headerDateLabel,
    required this.tasks,
    required this.todayCount,
    required this.updatedAt,
  });

  static const maxTasks = 3;
  /// ScheduleWidgetProvider와 공유하는 home_widget 키.
  static const storageKey = 'schedule_widget_data';

  final String headerDateLabel;
  final List<TodayWidgetTaskSnapshot> tasks;
  final int todayCount;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'headerDateLabel': headerDateLabel,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'todayCount': todayCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory TodayWidgetData.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'];
    return TodayWidgetData(
      headerDateLabel: json['headerDateLabel'] as String? ?? '',
      tasks: tasksJson is List
          ? tasksJson
                .whereType<Map<String, dynamic>>()
                .map(TodayWidgetTaskSnapshot.fromJson)
                .toList(growable: false)
          : const [],
      todayCount: json['todayCount'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

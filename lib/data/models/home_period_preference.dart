import 'dart:convert';

enum HomePeriod { today, week, month, all, custom }

/// Relative modes are recalculated on opening; custom dates remain fixed.
class HomePeriodPreference {
  const HomePeriodPreference({
    this.mode = HomePeriod.today,
    this.start,
    this.end,
  }) : assert(mode != HomePeriod.custom || (start != null && end != null));

  final HomePeriod mode;
  final DateTime? start;
  final DateTime? end;

  String encode() => jsonEncode({
    'mode': mode.name,
    if (mode == HomePeriod.custom) ...{
      'start': _dateString(start!),
      'end': _dateString(end!),
    },
  });

  static String _dateString(DateTime date) =>
      date.toIso8601String().split('T').first;

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final date = DateTime.tryParse(value);
    if (date == null ||
        date.year < 2000 ||
        date.year > 2100 ||
        _dateString(date) != value) {
      return null;
    }
    return date;
  }

  static HomePeriodPreference decode(String? raw) {
    try {
      final value = jsonDecode(raw ?? 'null');
      if (value is! Map) return const HomePeriodPreference();
      final mode = HomePeriod.values
          .where((mode) => mode.name == value['mode'])
          .firstOrNull;
      if (mode == null) return const HomePeriodPreference();
      if (mode != HomePeriod.custom) return HomePeriodPreference(mode: mode);
      final start = _parseDate(value['start']);
      final end = _parseDate(value['end']);
      if (start == null || end == null || end.isBefore(start)) {
        return const HomePeriodPreference();
      }
      return HomePeriodPreference(mode: mode, start: start, end: end);
    } on FormatException {
      return const HomePeriodPreference();
    }
  }
}

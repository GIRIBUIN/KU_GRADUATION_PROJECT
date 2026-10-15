import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart';

void main() {
  test(
    'Android widget fixture matches the real Drift database schema',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final rows = await database
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name IN "
            "('tasks','sub_tasks','tags','folders','task_tags','task_folders',"
            "'notification_settings','app_settings') ORDER BY name",
          )
          .get();
      final schema =
          '${rows.map((row) => row.read<String>('sql')).join(';\n')};\n';
      final fixture = File('android/app/src/test/resources/widget_schema.sql');
      if (Platform.environment['UPDATE_WIDGET_SCHEMA'] == '1') {
        fixture.parent.createSync(recursive: true);
        fixture.writeAsStringSync(schema);
      }
      expect(
        fixture.existsSync(),
        isTrue,
        reason:
            'Generate with UPDATE_WIDGET_SCHEMA=1 flutter test '
            'test/data/local/widget_schema_contract_test.dart',
      );
      expect(fixture.readAsStringSync().replaceAll('\r\n', '\n'), schema);
    },
  );
}

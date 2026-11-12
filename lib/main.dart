import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'widget_quick_create_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  runApp(const KuTaskApp());
}

/// 두 위젯의 등록 Activity가 호출하는 진입점. 릴리스 빌드에서도 제거되지 않게 유지한다.
@pragma('vm:entry-point')
Future<void> widgetQuickCreate() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  runApp(const WidgetQuickCreateApp());
}

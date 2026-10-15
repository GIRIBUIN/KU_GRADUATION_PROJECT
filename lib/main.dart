import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/services/apple_widget_bridge.dart';
import 'data/services/widget_workspace_controller.dart';
import 'presentation/widgets/widget_workspace_page.dart';

Future<void> main([List<String> args = const []]) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  await AppleWidgetBridge.initialize();
  final mode = args.where((arg) => arg.startsWith('--widget=')).firstOrNull;
  if (mode != null && isDesktopWidgetPlatform) {
    final kind = WidgetKind.values.firstWhere(
      (kind) => kind.name == mode.split('=').last,
      orElse: () => WidgetKind.today,
    );
    await prepareWidgetWindow();
    runApp(KuWidgetApp(kind: kind));
    return;
  }
  runApp(const KuTaskApp());
}

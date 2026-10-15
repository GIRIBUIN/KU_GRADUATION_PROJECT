import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Native WidgetKit targets and the Flutter app open one App Group database.
class AppleWidgetBridge {
  static const channel = MethodChannel('ku.todo/apple-widgets');
  static final _links = StreamController<Uri>.broadcast();
  static Stream<Uri> get links => _links.stream;
  static String? databasePath;
  static Uri? initialLink;
  static bool get supported =>
      const bool.fromEnvironment(
        'KU_NATIVE_APPLE_WIDGETS',
        defaultValue: true,
      ) &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<void> initialize() async {
    if (!supported) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetLink' && call.arguments is String) {
        final uri = Uri.tryParse(call.arguments as String);
        if (uri != null) {
          if (_links.hasListener) {
            _links.add(uri);
          } else {
            initialLink = uri;
          }
        }
      }
    });
    final documents = await getApplicationDocumentsDirectory();
    // Do not silently create an empty private DB if App Group signing is wrong.
    databasePath = await channel.invokeMethod<String>('prepareDatabase', {
      'sourcePath': '${documents.path}/ku_task_management.sqlite',
    });
    if (databasePath == null) {
      throw StateError('Apple 위젯 App Group 설정을 확인해주세요.');
    }
    final initial = await channel.invokeMethod<String>('initialLink');
    initialLink = initial == null ? null : Uri.tryParse(initial);
  }

  static Future<void> reload() async {
    if (supported) await channel.invokeMethod<void>('reload');
  }

  static Future<bool> consumeChanges() async =>
      supported &&
      (await channel.invokeMethod<bool>('consumeChanges') ?? false);
}

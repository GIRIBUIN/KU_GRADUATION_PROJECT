import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/task_models.dart';
import '../../data/services/notification_schedule_service.dart';

class LocalNotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationScheduleService scheduleService =
        const NotificationScheduleService(),
    DateTime Function()? now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _scheduleService = scheduleService,
       _now = now ?? DateTime.now;

  static const _channelId = 'task_due';
  static const _channelName = '작업 마감 알림';
  static const _channelDescription = '작업 마감 시각에 맞춰 알림을 보냅니다.';

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationScheduleService _scheduleService;
  final DateTime Function() _now;
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    if (androidGranted != null) {
      if (androidGranted) {
        await androidPlugin?.requestExactAlarmsPermission();
      }
      return androidGranted;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      return iosGranted;
    }

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macGranted = await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return macGranted ?? true;
  }

  Future<void> scheduleTaskNotification({
    required Task task,
    required NotificationSetting setting,
    bool requestPermissionBeforeScheduling = false,
  }) async {
    await initialize();
    await cancelTaskNotification(task.id);

    final schedule = _scheduleService.calculate(
      task: task,
      setting: setting,
      now: _now(),
    );
    if (schedule == null) {
      return;
    }

    if (requestPermissionBeforeScheduling) {
      final granted = await requestPermission();
      if (!granted) {
        return;
      }
    }

    final androidScheduleMode = await _androidScheduleMode();
    await _plugin.zonedSchedule(
      id: notificationIdForTask(task.id),
      title: 'KU Todo',
      body: '${task.title} 마감 알림',
      scheduledDate: tz.TZDateTime.from(schedule.scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: androidScheduleMode,
      payload: task.id,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await initialize();
    await _plugin.cancel(id: notificationIdForTask(taskId));
  }

  int notificationIdForTask(String taskId) {
    var hash = 0;
    for (final codeUnit in taskId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final canScheduleExact = await androidPlugin
        .canScheduleExactNotifications();
    return (canScheduleExact ?? true)
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'storage_service.dart';
import 'tts_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    final dynamic tzRaw = await FlutterTimezone.getLocalTimezone();
    final String tzNameString = RegExp(r'\(([^,]+),')
        .firstMatch(tzRaw.toString())
        ?.group(1)
        ?.trim() ?? 'America/New_York';
    tz.setLocalLocation(tz.getLocation(tzNameString));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    final String? key = response.payload;
    if (key != null && key.isNotEmpty) {
      TtsService.speakReminder(key);
    }
  }

  static Future<void> scheduleAll() async {
    await init();
    await _plugin.cancelAll();

    for (int i = 0; i < StorageService.reminderKeys.length; i++) {
      final key = StorageService.reminderKeys[i];
      final enabled = await StorageService.getReminderEnabled(key);
      if (!enabled) continue;

      final hour = await StorageService.getReminderHour(key);
      final minute = await StorageService.getReminderMinute(key);
      final label = StorageService.reminderLabels[key] ?? 'Reminder';

      await _scheduleDaily(
        id: i,
        key: key,
        title: label,
        hour: hour,
        minute: minute,
      );
    }
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static Future<void> showTestNotification() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'alzheimer_reminders',
      'Daily Reminders',
      channelDescription: 'Reminders for daily activities',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      id: 0,
      title: 'Time to take your medication',
      body: 'Tap to hear your reminder',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'medication',
    );
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String key,
    required String title,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'alzheimer_reminders',
      'Daily Reminders',
      channelDescription: 'Reminders for daily activities',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: 'Tap to hear your reminder',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: key,
    );
  }
}
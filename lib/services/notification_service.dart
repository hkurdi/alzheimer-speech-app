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

  static const _channelId = 'alzheimer_reminders';
  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    'Daily Reminders',
    channelDescription: 'Reminders for daily activities',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  static const _notificationDetails =
  NotificationDetails(android: _androidDetails);

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

    // Explicitly create the channel so it exists before any notifications
    // are scheduled — required on Android 8.0+ (API 26+).
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Daily Reminders',
        description: 'Reminders for daily activities',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
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
    await _plugin.show(
      id: 99,
      title: 'Time to take your medication',
      body: 'Tap to hear your reminder',
      notificationDetails: _notificationDetails,
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
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: 'Tap to hear your reminder',
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: key,
    );
  }
}
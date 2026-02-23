import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyPatientName = 'patient_name';
  static const _keyFamilyNames = 'family_names';
  static const _keyFamilyPaths = 'family_paths';
  static const _keyReminderEnabled = 'reminder_enabled_';
  static const _keyReminderHour = 'reminder_hour_';
  static const _keyReminderMinute = 'reminder_minute_';

  static Future<String> getPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPatientName) ?? 'Friend';
  }

  static Future<void> savePatientName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPatientName, name);
  }

  static Future<List<String>> getFamilyNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFamilyNames) ?? ['', '', '', ''];
  }

  static Future<List<String>> getFamilyPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFamilyPaths) ?? ['', '', '', ''];
  }

  static Future<void> saveFamilyNames(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFamilyNames, names);
  }

  static Future<void> saveFamilyPaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFamilyPaths, paths);
  }

  static const List<String> reminderKeys = [
    'medication',
    'breakfast',
    'lunch',
    'dinner',
    'hydration',
    'exercise',
    'family_call',
    'bedtime',
  ];

  static const Map<String, String> reminderLabels = {
    'medication':   'Take your medication',
    'breakfast':    'Time for breakfast',
    'lunch':        'Time for lunch',
    'dinner':       'Time for dinner',
    'hydration':    'Time to drink some water',
    'exercise':     'Time for a short walk',
    'family_call':  'Call your family',
    'bedtime':      'Time to get ready for bed',
  };

  static const Map<String, List<int>> reminderDefaults = {
    'medication':   [8, 0],
    'breakfast':    [8, 30],
    'lunch':        [12, 0],
    'dinner':       [18, 0],
    'hydration':    [10, 0],
    'exercise':     [9, 0],
    'family_call':  [15, 0],
    'bedtime':      [21, 0],
  };

  static Future<bool> getReminderEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderEnabled + key) ?? true;
  }

  static Future<void> saveReminderEnabled(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled + key, val);
  }

  static Future<int> getReminderHour(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderHour + key) ?? reminderDefaults[key]![0];
  }

  static Future<int> getReminderMinute(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderMinute + key) ?? reminderDefaults[key]![1];
  }

  static Future<void> saveReminderTime(String key, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour + key, hour);
    await prefs.setInt(_keyReminderMinute + key, minute);
  }
}
import 'package:hive_flutter/hive_flutter.dart';

/// Database service wrapping Hive initialization and box access.
class DatabaseService {
  static const String habitsBoxName = 'githabit_habits';
  static const String checkInsBoxName = 'githabit_checkins';
  static const String cacheBoxName = 'githabit_api_cache';
  static const String pomodoroBoxName = 'githabit_pomodoro';
  static const String settingsBoxName = 'githabit_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(habitsBoxName);
    await Hive.openBox<List>(checkInsBoxName);
    await Hive.openBox<String>(cacheBoxName);
    await Hive.openBox<Map>(pomodoroBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
  }

  static Box<Map> get habitsBox => Hive.box<Map>(habitsBoxName);
  static Box<List> get checkInsBox => Hive.box<List>(checkInsBoxName);
  static Box<String> get cacheBox => Hive.box<String>(cacheBoxName);
  static Box<Map> get pomodoroBox => Hive.box<Map>(pomodoroBoxName);
  static Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);
}


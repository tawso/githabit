import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:githabit/core/database/database_service.dart';
import 'package:githabit/features/pomodoro/data/pomodoro_repository.dart';

void main() {
  late Directory tempDir;
  late LocalPomodoroRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pomodoro_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(DatabaseService.pomodoroBoxName);
    repository = LocalPomodoroRepository();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('LocalPomodoroRepository Tests', () {
    test('starts with empty sessions without mock data and calculates stats', () async {
      final sessions = await repository.getSessions();
      expect(sessions.isEmpty, isTrue);

      final countToday = await repository.getCompletedSessionsToday();
      expect(countToday, equals(0));

      final minsToday = await repository.getTotalFocusMinutesToday();
      expect(minsToday, equals(0));
    });

    test('records a new focus session and updates count and focus minutes', () async {
      final initialCount = await repository.getCompletedSessionsToday();
      final initialMins = await repository.getTotalFocusMinutesToday();

      await repository.recordSession(25, tag: 'Rust');

      final newCount = await repository.getCompletedSessionsToday();
      final newMins = await repository.getTotalFocusMinutesToday();

      expect(newCount, equals(initialCount + 1));
      expect(newMins, equals(initialMins + 25));
    });
  });
}


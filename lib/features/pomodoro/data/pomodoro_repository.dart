import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../habits/domain/streak_calculator.dart';
import '../domain/pomodoro_session.dart';

abstract class PomodoroRepository {
  Future<List<PomodoroSession>> getSessions();
  Future<void> recordSession(int durationMinutes, {String tag = 'Coding'});
  Future<int> getCompletedSessionsToday();
  Future<int> getTotalFocusMinutesToday();
  Future<int> getTotalFocusMinutesThisWeek();
  Future<int> getTotalSessionsCount();
}

class LocalPomodoroRepository implements PomodoroRepository {
  @override
  Future<List<PomodoroSession>> getSessions() async {
    final box = DatabaseService.pomodoroBox;
    // Purge legacy mock sessions if present
    final legacyMockKeys = box.keys
        .where((k) => k.toString().startsWith('session_'))
        .toList();
    for (final k in legacyMockKeys) {
      await box.delete(k);
    }

    final List<PomodoroSession> sessions = [];
    for (final raw in box.values) {
      sessions.add(PomodoroSession.fromMap(raw));
    }
    sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sessions;
  }

  @override
  Future<void> recordSession(int durationMinutes, {String tag = 'Coding'}) async {
    final box = DatabaseService.pomodoroBox;
    final session = PomodoroSession(
      id: const Uuid().v4(),
      durationMinutes: durationMinutes,
      completedAt: DateTime.now(),
      tag: tag,
    );
    await box.put(session.id, session.toMap());
  }

  @override
  Future<int> getCompletedSessionsToday() async {
    final sessions = await getSessions();
    final today = StreakCalculator.normalizeDate(DateTime.now());

    return sessions.where((s) {
      final d = StreakCalculator.normalizeDate(s.completedAt);
      return d == today;
    }).length;
  }

  @override
  Future<int> getTotalFocusMinutesToday() async {
    final sessions = await getSessions();
    final today = StreakCalculator.normalizeDate(DateTime.now());

    int minutes = 0;
    for (final s in sessions) {
      if (StreakCalculator.normalizeDate(s.completedAt) == today) {
        minutes += s.durationMinutes;
      }
    }
    return minutes;
  }

  @override
  Future<int> getTotalFocusMinutesThisWeek() async {
    final sessions = await getSessions();
    final now = DateTime.now();
    final today = StreakCalculator.normalizeDate(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    int minutes = 0;
    for (final s in sessions) {
      final d = StreakCalculator.normalizeDate(s.completedAt);
      if (!d.isBefore(monday) && !d.isAfter(today)) {
        minutes += s.durationMinutes;
      }
    }
    return minutes;
  }

  @override
  Future<int> getTotalSessionsCount() async {
    final sessions = await getSessions();
    return sessions.length;
  }
}


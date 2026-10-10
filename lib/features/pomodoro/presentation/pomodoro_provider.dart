import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pomodoro_repository.dart';
import '../domain/pomodoro_session.dart';

class PomodoroStats {
  final int completedToday;
  final int focusMinutesToday;
  final int focusMinutesThisWeek;
  final int totalSessions;
  final List<PomodoroSession> recentSessions;

  const PomodoroStats({
    required this.completedToday,
    required this.focusMinutesToday,
    required this.focusMinutesThisWeek,
    required this.totalSessions,
    required this.recentSessions,
  });

  String get todayFormatted {
    final h = focusMinutesToday ~/ 60;
    final m = focusMinutesToday % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get weekFormatted {
    final h = focusMinutesThisWeek ~/ 60;
    final m = focusMinutesThisWeek % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

final pomodoroRepositoryProvider = Provider<PomodoroRepository>((ref) {
  return LocalPomodoroRepository();
});

class PomodoroNotifier extends AsyncNotifier<PomodoroStats> {
  @override
  Future<PomodoroStats> build() async {
    return _fetchStats();
  }

  Future<PomodoroStats> _fetchStats() async {
    final repo = ref.read(pomodoroRepositoryProvider);
    final completedToday = await repo.getCompletedSessionsToday();
    final todayMinutes = await repo.getTotalFocusMinutesToday();
    final weekMinutes = await repo.getTotalFocusMinutesThisWeek();
    final total = await repo.getTotalSessionsCount();
    final sessions = await repo.getSessions();

    return PomodoroStats(
      completedToday: completedToday,
      focusMinutesToday: todayMinutes,
      focusMinutesThisWeek: weekMinutes,
      totalSessions: total,
      recentSessions: sessions.take(10).toList(),
    );
  }

  Future<void> recordSession(int durationMinutes, {String tag = 'Coding'}) async {
    final repo = ref.read(pomodoroRepositoryProvider);
    await repo.recordSession(durationMinutes, tag: tag);
    state = AsyncData(await _fetchStats());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchStats());
  }
}

final pomodoroProvider =
    AsyncNotifierProvider<PomodoroNotifier, PomodoroStats>(PomodoroNotifier.new);


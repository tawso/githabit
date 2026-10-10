import 'package:githabit/core/database/database_service.dart';
import '../domain/habit.dart';
import '../domain/streak_calculator.dart';

abstract class HabitsRepository {
  Future<List<Habit>> getHabits();
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
  Future<List<DateTime>> getCheckInDates(String habitId);
  Future<bool> toggleCheckIn(String habitId, DateTime date);
  Future<int> calculateStreak(String habitId, [DateTime? relativeTo, Iterable<DateTime>? frozenDates]);
  Future<int> calculateLongestStreak(String habitId, [Iterable<DateTime>? frozenDates]);
  Future<List<bool>> getLast7DaysStatus(String habitId, [DateTime? relativeTo]);
  Future<bool> isCompletedOnDate(String habitId, DateTime date);
  Future<Map<DateTime, int>> getAllHabitsContributionMap();
}

class LocalHabitsRepository implements HabitsRepository {

  @override
  Future<List<Habit>> getHabits() async {
    final box = DatabaseService.habitsBox;
    // Purge legacy mock habits if present
    const legacyMockIds = {'habit_threads', 'habit_saas', 'habit_reading'};
    for (final id in legacyMockIds) {
      if (box.containsKey(id)) {
        await box.delete(id);
        await DatabaseService.checkInsBox.delete(id);
      }
    }

    final List<Habit> habits = [];
    for (final raw in box.values) {
      habits.add(Habit.fromMap(raw));
    }

    habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return habits;
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final box = DatabaseService.habitsBox;
    await box.put(habit.id, habit.toMap());
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final habitsBox = DatabaseService.habitsBox;
    final checkInsBox = DatabaseService.checkInsBox;

    await habitsBox.delete(habitId);
    await checkInsBox.delete(habitId);
  }

  @override
  Future<List<DateTime>> getCheckInDates(String habitId) async {
    final box = DatabaseService.checkInsBox;
    final rawList = box.get(habitId);
    if (rawList == null) return [];

    final List<DateTime> dates = [];
    for (final item in rawList) {
      if (item is String) {
        dates.add(DateTime.parse(item));
      } else if (item is Map) {
        dates.add(DateTime.parse(item['date'] as String));
      }
    }
    return dates;
  }

  @override
  Future<bool> toggleCheckIn(String habitId, DateTime date) async {
    final box = DatabaseService.checkInsBox;
    final norm = StreakCalculator.normalizeDate(date);
    final normStr = norm.toIso8601String();

    final rawList = box.get(habitId) ?? [];
    final List<String> currentList = List<String>.from(
      rawList.map((e) => e is Map ? e['date'] as String : e.toString()),
    );

    final exists = currentList.contains(normStr);
    if (exists) {
      currentList.remove(normStr);
      await box.put(habitId, currentList);
      return false; // Checked out
    } else {
      currentList.add(normStr);
      await box.put(habitId, currentList);
      return true; // Checked in
    }
  }

  @override
  Future<int> calculateStreak(String habitId, [DateTime? relativeTo, Iterable<DateTime>? frozenDates]) async {
    final dates = await getCheckInDates(habitId);
    return StreakCalculator.calculateCurrentStreak(
      dates,
      frozenDates: frozenDates,
      relativeTo: relativeTo,
    );
  }

  @override
  Future<int> calculateLongestStreak(String habitId, [Iterable<DateTime>? frozenDates]) async {
    final dates = await getCheckInDates(habitId);
    return StreakCalculator.calculateLongestStreak(
      dates,
      frozenDates: frozenDates,
    );
  }

  @override
  Future<List<bool>> getLast7DaysStatus(
    String habitId, [
    DateTime? relativeTo,
  ]) async {
    final dates = await getCheckInDates(habitId);
    return StreakCalculator.getLastNDaysStatus(dates, 7, relativeTo: relativeTo);
  }

  @override
  Future<bool> isCompletedOnDate(String habitId, DateTime date) async {
    final dates = await getCheckInDates(habitId);
    final norm = StreakCalculator.normalizeDate(date);
    return dates.map(StreakCalculator.normalizeDate).contains(norm);
  }

  @override
  Future<Map<DateTime, int>> getAllHabitsContributionMap() async {
    final box = DatabaseService.checkInsBox;
    final Map<DateTime, int> result = {};

    for (final key in box.keys) {
      final dates = await getCheckInDates(key.toString());
      for (final d in dates) {
        final norm = StreakCalculator.normalizeDate(d);
        result[norm] = (result[norm] ?? 0) + 1;
      }
    }

    return result;
  }
}


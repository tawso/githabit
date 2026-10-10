import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../freeze/presentation/freeze_provider.dart';
import '../../github/presentation/github_provider.dart';
import '../domain/streak_calculator.dart';
import 'habits_provider.dart';

/// Representation of a single weekday (Monday = 0 ... Sunday = 6)
class WeekDayStatus {
  final int weekdayIndex; // 0 for Mon, 6 for Sun
  final String label; // Mon, Tue, Wed...
  final DateTime date;
  final bool isPast;
  final bool isToday;
  final bool isFuture;
  final bool isCompleted;
  final bool isFrozen;
  final int completedHabitsCount;
  final int totalHabitsCount;

  const WeekDayStatus({
    required this.weekdayIndex,
    required this.label,
    required this.date,
    required this.isPast,
    required this.isToday,
    required this.isFuture,
    required this.isCompleted,
    required this.isFrozen,
    required this.completedHabitsCount,
    required this.totalHabitsCount,
  });
}

/// Comprehensive model for user developer streak & daily goal metrics
class StreakMetrics {
  final int currentStreak;
  final int longestStreak;
  final int totalHabits;
  final int completedToday;
  final double progressPercent; // 0.0 to 1.0
  final bool isGoalAchievedToday;
  final List<WeekDayStatus> weekDays;

  const StreakMetrics({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalHabits,
    required this.completedToday,
    required this.progressPercent,
    required this.isGoalAchievedToday,
    required this.weekDays,
  });

  int get progressPercentInt => (progressPercent * 100).round();
}

/// Single source of truth for user streak & daily habits progression
final streakProvider = Provider<StreakMetrics>((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final ghActivity = ref.watch(githubActivityProvider).value;
  final freezeState = ref.watch(streakFreezeProvider).value;
  final frozenDates = freezeState?.frozenDateTimes ?? [];

  final now = DateTime.now();
  final today = StreakCalculator.normalizeDate(now);

  // 1. Gather all active check-in dates across all habits
  final Set<DateTime> allHabitCheckInDates = {};
  for (final habit in habits) {
    for (final d in habit.checkInDates) {
      allHabitCheckInDates.add(StreakCalculator.normalizeDate(d));
    }
  }

  // 2. Include GitHub active contribution dates if available
  final Set<DateTime> ghDates = {};
  if (ghActivity != null) {
    for (final entry in ghActivity.contributionsMap.entries) {
      if (entry.value > 0) {
        ghDates.add(StreakCalculator.normalizeDate(entry.key));
      }
    }
  }

  final Set<DateTime> combinedActiveDates = {
    ...allHabitCheckInDates,
    ...ghDates,
  };

  // 3. Compute continuous daily active streak (grace period + frozen days handled)
  final activityDailyStreak = StreakCalculator.calculateCurrentStreak(
    combinedActiveDates,
    frozenDates: frozenDates,
    relativeTo: today,
  );

  // 4. Maximum streak among individual habits
  final maxHabitCurrentStreak = habits.isEmpty
      ? 0
      : habits.map((h) => h.streak).fold<int>(0, math.max);

  final ghStreak = ghActivity?.currentStreak ?? 0;

  // Real effective streak across all sources
  final effectiveStreak = math.max(
    activityDailyStreak,
    math.max(maxHabitCurrentStreak, ghStreak),
  );

  // 5. Longest streak computation
  final activityLongestStreak = StreakCalculator.calculateLongestStreak(
    combinedActiveDates,
    frozenDates: frozenDates,
  );
  final maxHabitLongestStreak = habits.isEmpty
      ? 0
      : habits.map((h) => h.longestStreak).fold<int>(0, math.max);
  final ghLongestStreak = ghActivity?.longestStreak ?? 0;

  final effectiveLongestStreak = math.max(
    activityLongestStreak,
    math.max(maxHabitLongestStreak, ghLongestStreak),
  );

  // 6. Daily Goal metrics for today
  final totalHabits = habits.length;
  final completedToday = habits.where((h) => h.isCompletedToday).length;
  final progressPercent = totalHabits > 0
      ? (completedToday / totalHabits).clamp(0.0, 1.0)
      : 0.0;
  final isGoalAchievedToday = totalHabits > 0 && completedToday >= totalHabits;

  // 7. Calculate 7-day status for the current week (Monday to Sunday)
  // DateTime.weekday: Mon=1 ... Sun=7
  final mondayOffset = now.weekday - 1;
  final startOfWeek = DateTime(today.year, today.month, today.day - mondayOffset);

  const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<WeekDayStatus> weekDays = [];

  for (int i = 0; i < 7; i++) {
    final dayDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
    final isPast = dayDate.isBefore(today);
    final isCurrentDay = dayDate.year == today.year &&
        dayDate.month == today.month &&
        dayDate.day == today.day;
    final isFuture = dayDate.isAfter(today);

    final isFrozen = freezeState?.isDateFrozen(dayDate) ?? false;

    // Count how many habits completed on this calendar day
    int completedOnDay = 0;
    for (final h in habits) {
      if (h.checkInDates.any((d) => StreakCalculator.normalizeDate(d) == dayDate)) {
        completedOnDay++;
      }
    }

    final hasGhCommits = ghDates.contains(dayDate);

    bool isCompleted = false;
    if (isCurrentDay) {
      isCompleted = isGoalAchievedToday;
    } else if (isPast) {
      // Past day is considered completed if user met habits, committed code, or froze it
      isCompleted = (completedOnDay > 0) || hasGhCommits || isFrozen;
    } else {
      isCompleted = false;
    }

    weekDays.add(WeekDayStatus(
      weekdayIndex: i,
      label: weekdayNames[i],
      date: dayDate,
      isPast: isPast,
      isToday: isCurrentDay,
      isFuture: isFuture,
      isCompleted: isCompleted,
      isFrozen: isFrozen,
      completedHabitsCount: completedOnDay,
      totalHabitsCount: totalHabits,
    ));
  }

  return StreakMetrics(
    currentStreak: effectiveStreak,
    longestStreak: effectiveLongestStreak,
    totalHabits: totalHabits,
    completedToday: completedToday,
    progressPercent: progressPercent,
    isGoalAchievedToday: isGoalAchievedToday,
    weekDays: weekDays,
  );
});


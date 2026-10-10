/// High precision streak calculation logic with edge case coverage:
/// - Same day deduplication
/// - Grace period for today (active streak maintained if yesterday was completed)
/// - Chronological normalization
/// - Longest streak across historical datasets
class StreakCalculator {
  StreakCalculator._();

  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime _prevDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day - 1);

  /// Calculates the current streak in days relative to [relativeTo] (defaults to today).
  ///
  /// If today is completed, streak includes today and counts consecutive prior days.
  /// If today is not completed yet, but yesterday was completed, the streak from yesterday
  /// is preserved as active (grace period).
  /// If [frozenDates] contains protected dates, those days bridge gaps without breaking streak.
  /// If neither today nor yesterday is completed (and not frozen), the streak is 0.
  static int calculateCurrentStreak(
    Iterable<DateTime> dates, {
    Iterable<DateTime>? frozenDates,
    DateTime? relativeTo,
  }) {
    final normalizedDates = dates.map(normalizeDate).toSet();
    final normalizedFrozen = (frozenDates ?? const []).map(normalizeDate).toSet();
    final combinedSet = {...normalizedDates, ...normalizedFrozen};

    if (combinedSet.isEmpty) return 0;

    final today = normalizeDate(relativeTo ?? DateTime.now());
    final yesterday = _prevDay(today);

    if (combinedSet.contains(today)) {
      int streak = 1;
      DateTime cursor = yesterday;
      while (combinedSet.contains(cursor)) {
        streak++;
        cursor = _prevDay(cursor);
      }
      return streak;
    } else if (combinedSet.contains(yesterday)) {
      // Grace period: today is not done yet, but yesterday was done or frozen
      int streak = 1;
      DateTime cursor = _prevDay(yesterday);
      while (combinedSet.contains(cursor)) {
        streak++;
        cursor = _prevDay(cursor);
      }
      return streak;
    }

    return 0;
  }

  /// Calculates the longest unbroken streak of consecutive days in history.
  static int calculateLongestStreak(
    Iterable<DateTime> dates, {
    Iterable<DateTime>? frozenDates,
  }) {
    final normalizedDates = dates.map(normalizeDate).toSet();
    final normalizedFrozen = (frozenDates ?? const []).map(normalizeDate).toSet();
    final combinedSet = {...normalizedDates, ...normalizedFrozen};

    if (combinedSet.isEmpty) return 0;

    final sorted = combinedSet.toList()..sort((a, b) => a.compareTo(b));

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];

      // Difference in calendar days
      final expectedNextDay = DateTime(prev.year, prev.month, prev.day + 1);
      if (curr.year == expectedNextDay.year &&
          curr.month == expectedNextDay.month &&
          curr.day == expectedNextDay.day) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Returns completion status booleans for the last [daysCount] days up to [relativeTo].
  /// Index 0 is (relativeTo - daysCount + 1), last index is relativeTo.
  static List<bool> getLastNDaysStatus(
    Iterable<DateTime> dates,
    int daysCount, {
    DateTime? relativeTo,
  }) {
    final target = normalizeDate(relativeTo ?? DateTime.now());
    final set = dates.map(normalizeDate).toSet();

    final List<bool> result = [];
    for (int i = daysCount - 1; i >= 0; i--) {
      final day = DateTime(target.year, target.month, target.day - i);
      result.add(set.contains(day));
    }
    return result;
  }

  /// Converts a collection of check-ins to a date-frequency contribution map.
  static Map<DateTime, int> toContributionMap(Iterable<DateTime> dates) {
    final Map<DateTime, int> map = {};
    for (final date in dates) {
      final norm = normalizeDate(date);
      map[norm] = (map[norm] ?? 0) + 1;
    }
    return map;
  }
}


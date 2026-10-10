import 'package:flutter_test/flutter_test.dart';
import 'package:githabit/features/habits/domain/streak_calculator.dart';

void main() {
  group('StreakCalculator Unit Tests', () {
    final referenceDate = DateTime(2026, 10, 8); // Anchor date

    test('returns 0 for empty dates list', () {
      final current = StreakCalculator.calculateCurrentStreak(
        [],
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak([]);

      expect(current, 0);
      expect(longest, 0);
    });

    test('returns 1 when check-in is only on reference date (today)', () {
      final dates = [referenceDate];
      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(dates);

      expect(current, 1);
      expect(longest, 1);
    });

    test('grace period: returns active streak when completed yesterday but not yet today', () {
      final yesterday = DateTime(referenceDate.year, referenceDate.month, referenceDate.day - 1);
      final dates = [yesterday];

      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );

      expect(current, 1);
    });

    test('returns 0 streak when last check-in was 2 days ago (broken streak)', () {
      final twoDaysAgo = DateTime(referenceDate.year, referenceDate.month, referenceDate.day - 2);
      final dates = [twoDaysAgo];

      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(dates);

      expect(current, 0);
      expect(longest, 1);
    });

    test('correctly calculates 5 consecutive days streak ending today', () {
      final dates = List.generate(
        5,
        (i) => DateTime(referenceDate.year, referenceDate.month, referenceDate.day - i),
      );

      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(dates);

      expect(current, 5);
      expect(longest, 5);
    });

    test('correctly calculates 4 consecutive days streak ending yesterday (grace period)', () {
      final dates = List.generate(
        4,
        (i) => DateTime(referenceDate.year, referenceDate.month, referenceDate.day - (i + 1)),
      );

      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(dates);

      expect(current, 4);
      expect(longest, 4);
    });

    test('deduplicates multiple check-ins on the same day', () {
      final todayMorning = DateTime(2026, 10, 8, 8, 30);
      final todayNoon = DateTime(2026, 10, 8, 12, 15);
      final todayNight = DateTime(2026, 10, 8, 22, 00);
      final yesterdayMorning = DateTime(2026, 10, 7, 9, 00);
      final yesterdayEvening = DateTime(2026, 10, 7, 19, 45);

      final dates = [
        todayMorning,
        todayNoon,
        todayNight,
        yesterdayMorning,
        yesterdayEvening,
      ];

      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(dates);

      expect(current, 2);
      expect(longest, 2);
    });

    test('handles unordered and scrambled date entries properly', () {
      final dates = [
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 8),
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 5),
      ];

      final current = StreakCalculator.calculateCurrentStreak(
        dates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(dates);

      expect(current, 4);
      expect(longest, 4);
    });

    test('calculates longest streak independently from current streak', () {
      // Past streak of 6 days: Sept 10 to Sept 15
      final pastStreak = List.generate(
        6,
        (i) => DateTime(2026, 9, 10 + i),
      );

      // Current streak of 2 days: Oct 7 and Oct 8
      final currentStreak = [
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 8),
      ];

      final allDates = [...pastStreak, ...currentStreak];

      final current = StreakCalculator.calculateCurrentStreak(
        allDates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(allDates);

      expect(current, 2);
      expect(longest, 6);
    });

    test('getLastNDaysStatus outputs exact boolean sequence', () {
      final dates = [
        DateTime(2026, 10, 8), // today
        DateTime(2026, 10, 6), // 2 days ago
        DateTime(2026, 10, 5), // 3 days ago
      ];

      final status7 = StreakCalculator.getLastNDaysStatus(
        dates,
        7,
        relativeTo: referenceDate,
      );

      // Index 0: Oct 2 (-6 days) -> false
      // Index 1: Oct 3 (-5 days) -> false
      // Index 2: Oct 4 (-4 days) -> false
      // Index 3: Oct 5 (-3 days) -> true
      // Index 4: Oct 6 (-2 days) -> true
      // Index 5: Oct 7 (-1 days) -> false
      // Index 6: Oct 8 (today)   -> true
      expect(status7, [false, false, false, true, true, false, true]);
    });

    test('toContributionMap computes frequencies accurately', () {
      final dates = [
        referenceDate,
        referenceDate,
        DateTime(2026, 10, 7),
      ];

      final map = StreakCalculator.toContributionMap(dates);
      expect(map[referenceDate], 2);
      expect(map[DateTime(2026, 10, 7)], 1);
    });

    test('frozen date bridges missing day in active streak', () {
      // User coded on Oct 8 (today), missed Oct 7 (yesterday), coded on Oct 6 and Oct 5
      // With Oct 7 frozen, streak should be 4 days (Oct 8, Oct 7 [frozen], Oct 6, Oct 5)
      final dates = [
        referenceDate, // Oct 8
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 5),
      ];
      final frozenDates = [
        DateTime(2026, 10, 7), // Oct 7 frozen
      ];

      final streak = StreakCalculator.calculateCurrentStreak(
        dates,
        frozenDates: frozenDates,
        relativeTo: referenceDate,
      );
      final longest = StreakCalculator.calculateLongestStreak(
        dates,
        frozenDates: frozenDates,
      );

      expect(streak, 4);
      expect(longest, 4);
    });

    test('frozen yesterday bridges grace period when today is not completed', () {
      // User missed Oct 8 (today), missed Oct 7 (yesterday) but froze Oct 7, and coded on Oct 6
      final dates = [
        DateTime(2026, 10, 6),
      ];
      final frozenDates = [
        DateTime(2026, 10, 7), // Oct 7 frozen
      ];

      final streak = StreakCalculator.calculateCurrentStreak(
        dates,
        frozenDates: frozenDates,
        relativeTo: referenceDate,
      );

      expect(streak, 2);
    });
  });
}


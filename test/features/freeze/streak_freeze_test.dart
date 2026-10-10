import 'package:flutter_test/flutter_test.dart';
import 'package:githabit/features/freeze/domain/streak_freeze_state.dart';

void main() {
  group('StreakFreezeState Unit Tests', () {
    test('default state has 2 available freezes and empty frozen dates', () {
      const state = StreakFreezeState();
      expect(state.availableFreezes, 2);
      expect(state.frozenDates, isEmpty);
      expect(state.frozenDateTimes, isEmpty);
    });

    test('isDateFrozen correctly identifies frozen dates', () {
      final today = DateTime(2026, 10, 9);
      final yesterday = DateTime(2026, 10, 8);
      final state = StreakFreezeState(
        availableFreezes: 1,
        frozenDates: ['2026-10-09'],
      );

      expect(state.isDateFrozen(today), isTrue);
      expect(state.isDateFrozen(yesterday), isFalse);
    });

    test('serializes and deserializes from Map properly', () {
      final original = StreakFreezeState(
        availableFreezes: 4,
        frozenDates: ['2026-10-01', '2026-10-05'],
      );

      final map = original.toMap();
      final restored = StreakFreezeState.fromMap(map);

      expect(restored.availableFreezes, 4);
      expect(restored.frozenDates, ['2026-10-01', '2026-10-05']);
      expect(restored.frozenDateTimes.length, 2);
    });

    test('copyWith updates fields without mutating unchanged fields', () {
      const state = StreakFreezeState(availableFreezes: 2, frozenDates: ['2026-10-01']);
      final updated = state.copyWith(availableFreezes: 1);

      expect(updated.availableFreezes, 1);
      expect(updated.frozenDates, ['2026-10-01']);
    });
  });
}


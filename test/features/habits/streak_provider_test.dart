import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:githabit/features/freeze/domain/streak_freeze_state.dart';
import 'package:githabit/features/freeze/presentation/freeze_provider.dart';
import 'package:githabit/features/github/domain/github_activity_model.dart';
import 'package:githabit/features/github/presentation/github_provider.dart';
import 'package:githabit/features/habits/domain/habit.dart';
import 'package:githabit/features/habits/domain/streak_calculator.dart';
import 'package:githabit/features/habits/presentation/habits_provider.dart';
import 'package:githabit/features/habits/presentation/streak_provider.dart';

void main() {
  group('streakProvider Unit Tests', () {
    test('returns 0 streak and 0 progress when habits and github are empty', () async {
      final now = DateTime.now();
      final emptyGh = GithubActivityModel(
        username: 'test',
        totalContributions: 0,
        currentStreak: 0,
        longestStreak: 0,
        contributionsMap: const {},
        lastFetched: now,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(() => _MockHabitsNotifier([])),
          githubActivityProvider.overrideWith((ref) => Future.value(emptyGh)),
          streakFreezeProvider.overrideWith(() => _MockFreezeNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.future);
      await container.read(streakFreezeProvider.future);

      final metrics = container.read(streakProvider);
      expect(metrics.currentStreak, 0);
      expect(metrics.longestStreak, 0);
      expect(metrics.totalHabits, 0);
      expect(metrics.completedToday, 0);
      expect(metrics.progressPercent, 0.0);
      expect(metrics.isGoalAchievedToday, false);
      expect(metrics.weekDays.length, 7);
    });

    test('accurately computes habit streaks and daily goal progression', () async {
      final now = DateTime.now();
      final today = StreakCalculator.normalizeDate(now);
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      final emptyGh = GithubActivityModel(
        username: 'test',
        totalContributions: 0,
        currentStreak: 0,
        longestStreak: 0,
        contributionsMap: const {},
        lastFetched: now,
      );

      final habits = [
        HabitUiModel(
          habit: Habit(
            id: 'h1',
            title: 'Coding',
            createdAt: now,
          ),
          streak: 12,
          longestStreak: 20,
          isCompletedToday: true,
          last7Days: [false, true, true, true, true, true, true],
          checkInDates: [today, yesterday],
        ),
        HabitUiModel(
          habit: Habit(
            id: 'h2',
            title: 'Reading Docs',
            createdAt: now,
          ),
          streak: 5,
          longestStreak: 10,
          isCompletedToday: false,
          last7Days: [false, false, true, true, true, true, false],
          checkInDates: [yesterday],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(() => _MockHabitsNotifier(habits)),
          githubActivityProvider.overrideWith((ref) => Future.value(emptyGh)),
          streakFreezeProvider.overrideWith(() => _MockFreezeNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.future);
      await container.read(streakFreezeProvider.future);

      final metrics = container.read(streakProvider);
      expect(metrics.currentStreak, 12);
      expect(metrics.longestStreak, 20);
      expect(metrics.totalHabits, 2);
      expect(metrics.completedToday, 1);
      expect(metrics.progressPercent, 0.5);
      expect(metrics.isGoalAchievedToday, false);
    });

    test('honors GitHub streak and freeze protection', () async {
      final now = DateTime.now();
      final today = StreakCalculator.normalizeDate(now);
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      final ghMock = GithubActivityModel(
        username: 'octocat',
        totalContributions: 350,
        currentStreak: 24,
        longestStreak: 45,
        contributionsMap: {today: 5, yesterday: 3},
        lastFetched: now,
      );

      final freezeState = StreakFreezeState(
        availableFreezes: 3,
        frozenDates: [StreakFreezeState.formatDateKey(today.subtract(const Duration(days: 2)))],
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(() => _MockHabitsNotifier([])),
          githubActivityProvider.overrideWith((ref) => Future.value(ghMock)),
          streakFreezeProvider.overrideWith(() => _MockFreezeNotifier(freezeState)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.future);
      await container.read(streakFreezeProvider.future);
      await container.read(githubActivityProvider.future);

      final metrics = container.read(streakProvider);
      expect(metrics.currentStreak, 24);
      expect(metrics.longestStreak, 45);
    });
  });
}

class _MockHabitsNotifier extends HabitsNotifier {
  final List<HabitUiModel> _list;
  _MockHabitsNotifier(this._list);

  @override
  Future<List<HabitUiModel>> build() async => _list;
}

class _MockFreezeNotifier extends StreakFreezeNotifier {
  final StreakFreezeState _state;
  _MockFreezeNotifier([this._state = const StreakFreezeState()]);

  @override
  Future<StreakFreezeState> build() async => _state;
}

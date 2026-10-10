import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:githabit/features/dashboard/widgets/day_streak_sheet.dart';
import 'package:githabit/features/freeze/domain/streak_freeze_state.dart';
import 'package:githabit/features/freeze/presentation/freeze_provider.dart';
import 'package:githabit/features/habits/domain/habit.dart';
import 'package:githabit/features/habits/presentation/habits_provider.dart';

void main() {
  testWidgets('DayStreakSheet renders correctly with habits and stats', (tester) async {
    final now = DateTime.now();
    final habits = [
      HabitUiModel(
        habit: Habit(
          id: 'test_habit_1',
          title: 'Review PRs',
          category: HabitCategory.coding,
          createdAt: now,
        ),
        streak: 15,
        longestStreak: 25,
        isCompletedToday: false,
        last7Days: [true, true, true, true, true, false, false],
        checkInDates: [now.subtract(const Duration(days: 1))],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith(() => _MockHabitsNotifier(habits)),
          streakFreezeProvider.overrideWith(
            () => _MockFreezeNotifier(const StreakFreezeState(availableFreezes: 2)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DayStreakSheet.show(context),
                child: const Text('Open Streak Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to open sheet
    await tester.tap(find.text('Open Streak Sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify modal elements render
    expect(find.text('Developer Streak & Habits'), findsOneWidget);
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('DAILY DEV GOAL'), findsOneWidget);
    expect(find.text("TODAY'S HABITS"), findsOneWidget);
    expect(find.text('Review PRs'), findsOneWidget);
    expect(find.text('Check-In All Today'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Best'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Shields'), findsOneWidget);
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

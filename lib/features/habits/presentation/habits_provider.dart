import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../freeze/presentation/freeze_provider.dart';
import '../data/habits_repository.dart';
import '../domain/habit.dart';

/// Presentation model bundling habit data and computed streak metrics.
class HabitUiModel {
  final Habit habit;
  final int streak;
  final int longestStreak;
  final bool isCompletedToday;
  final List<bool> last7Days;
  final List<DateTime> checkInDates;

  const HabitUiModel({
    required this.habit,
    required this.streak,
    required this.longestStreak,
    required this.isCompletedToday,
    required this.last7Days,
    this.checkInDates = const [],
  });

  HabitUiModel copyWith({
    Habit? habit,
    int? streak,
    int? longestStreak,
    bool? isCompletedToday,
    List<bool>? last7Days,
    List<DateTime>? checkInDates,
  }) {
    return HabitUiModel(
      habit: habit ?? this.habit,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      last7Days: last7Days ?? this.last7Days,
      checkInDates: checkInDates ?? this.checkInDates,
    );
  }
}

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return LocalHabitsRepository();
});

class HabitsNotifier extends AsyncNotifier<List<HabitUiModel>> {
  @override
  Future<List<HabitUiModel>> build() async {
    return _fetchHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchHabits());
  }

  Future<List<HabitUiModel>> _fetchHabits() async {
    final repo = ref.read(habitsRepositoryProvider);
    final habits = await repo.getHabits();
    final now = DateTime.now();

    final freezeRepo = ref.read(freezeRepositoryProvider);
    final freezeState = await freezeRepo.getFreezeState();
    final frozenDates = freezeState.frozenDateTimes;

    final List<HabitUiModel> uiList = [];
    for (final h in habits) {
      final streak = await repo.calculateStreak(h.id, now, frozenDates);
      final longest = await repo.calculateLongestStreak(h.id, frozenDates);
      final completedToday = await repo.isCompletedOnDate(h.id, now);
      final last7Days = await repo.getLast7DaysStatus(h.id, now);
      final checkInDates = await repo.getCheckInDates(h.id);

      uiList.add(HabitUiModel(
        habit: h,
        streak: streak,
        longestStreak: longest,
        isCompletedToday: completedToday,
        last7Days: last7Days,
        checkInDates: checkInDates,
      ));
    }
    return uiList;
  }

  Future<void> toggleCheckIn(String habitId, [DateTime? date]) async {
    final currentList = state.value;
    if (currentList == null) return;

    final targetDate = date ?? DateTime.now();
    final repo = ref.read(habitsRepositoryProvider);
    await repo.toggleCheckIn(habitId, targetDate);

    final freezeRepo = ref.read(freezeRepositoryProvider);
    final freezeState = await freezeRepo.getFreezeState();
    final frozenDates = freezeState.frozenDateTimes;

    final now = DateTime.now();
    final streak = await repo.calculateStreak(habitId, now, frozenDates);
    final longest = await repo.calculateLongestStreak(habitId, frozenDates);
    final completedToday = await repo.isCompletedOnDate(habitId, now);
    final last7 = await repo.getLast7DaysStatus(habitId, now);
    final checkInDates = await repo.getCheckInDates(habitId);

    state = AsyncData([
      for (final item in currentList)
        if (item.habit.id == habitId)
          item.copyWith(
            streak: streak,
            longestStreak: longest,
            isCompletedToday: completedToday,
            last7Days: last7,
            checkInDates: checkInDates,
          )
        else
          item,
    ]);
  }

  /// Checks in all uncompleted habits for today. Returns count of newly checked in habits.
  Future<int> checkInAllToday() async {
    final habits = state.value ?? [];
    if (habits.isEmpty) return 0;

    final repo = ref.read(habitsRepositoryProvider);
    final now = DateTime.now();
    int count = 0;

    for (final h in habits) {
      final isDone = await repo.isCompletedOnDate(h.habit.id, now);
      if (!isDone) {
        await repo.toggleCheckIn(h.habit.id, now);
        count++;
      }
    }

    if (count > 0) {
      await loadHabits();
    }
    return count;
  }

  Future<void> addHabit({
    required String title,
    required HabitCategory category,
    String? description,
  }) async {
    final repo = ref.read(habitsRepositoryProvider);
    final newHabit = Habit(
      id: const Uuid().v4(),
      title: title,
      category: category,
      description: description,
      createdAt: DateTime.now(),
    );

    await repo.saveHabit(newHabit);
    state = AsyncData(await _fetchHabits());
  }

  Future<void> updateHabit(Habit habit) async {
    final repo = ref.read(habitsRepositoryProvider);
    await repo.saveHabit(habit);
    state = AsyncData(await _fetchHabits());
  }

  Future<void> restoreBackup(Map<String, dynamic> data) async {
    final repo = ref.read(habitsRepositoryProvider);
    final rawHabits = (data['habits'] as List?) ?? [];
    for (final raw in rawHabits) {
      if (raw is Map) {
        await repo.saveHabit(Habit.fromMap(raw));
      }
    }
    state = AsyncData(await _fetchHabits());
  }

  Future<void> deleteHabit(String habitId) async {
    final repo = ref.read(habitsRepositoryProvider);
    await repo.deleteHabit(habitId);
    final currentList = state.value;
    if (currentList != null) {
      state = AsyncData(
        currentList.where((item) => item.habit.id != habitId).toList(),
      );
    }
  }
}

final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, List<HabitUiModel>>(HabitsNotifier.new);

final habitsHeatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  ref.watch(habitsProvider);
  final repo = ref.read(habitsRepositoryProvider);
  return repo.getAllHabitsContributionMap();
});

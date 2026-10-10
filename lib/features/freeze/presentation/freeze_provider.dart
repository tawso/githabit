import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../habits/domain/streak_calculator.dart';
import '../../habits/presentation/habits_provider.dart';
import '../data/freeze_repository.dart';
import '../domain/streak_freeze_state.dart';

final freezeRepositoryProvider = Provider<FreezeRepository>((ref) {
  return LocalFreezeRepository();
});

class StreakFreezeNotifier extends AsyncNotifier<StreakFreezeState> {
  @override
  Future<StreakFreezeState> build() async {
    final repo = ref.read(freezeRepositoryProvider);
    return repo.getFreezeState();
  }

  static String _formatDateKey(DateTime dt) {
    final norm = StreakCalculator.normalizeDate(dt);
    final y = norm.year.toString().padLeft(4, '0');
    final m = norm.month.toString().padLeft(2, '0');
    final d = norm.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<bool> freezeDate(DateTime date) async {
    final current = state.value ?? const StreakFreezeState();
    final key = _formatDateKey(date);

    if (current.availableFreezes <= 0 || current.frozenDates.contains(key)) {
      return false;
    }

    final updated = current.copyWith(
      availableFreezes: current.availableFreezes - 1,
      frozenDates: [...current.frozenDates, key],
    );

    final repo = ref.read(freezeRepositoryProvider);
    await repo.saveFreezeState(updated);
    state = AsyncData(updated);

    // Invalidate habits to recompute streaks with the new frozen date
    ref.read(habitsProvider.notifier).loadHabits();
    return true;
  }

  Future<bool> unfreezeDate(DateTime date) async {
    final current = state.value ?? const StreakFreezeState();
    final key = _formatDateKey(date);

    if (!current.frozenDates.contains(key)) {
      return false;
    }

    final updatedList = List<String>.from(current.frozenDates)..remove(key);
    final updated = current.copyWith(
      availableFreezes: current.availableFreezes + 1,
      frozenDates: updatedList,
    );

    final repo = ref.read(freezeRepositoryProvider);
    await repo.saveFreezeState(updated);
    state = AsyncData(updated);

    ref.read(habitsProvider.notifier).loadHabits();
    return true;
  }

  Future<void> earnFreeze([int count = 1]) async {
    final current = state.value ?? const StreakFreezeState();
    final updated = current.copyWith(
      availableFreezes: current.availableFreezes + count,
    );

    final repo = ref.read(freezeRepositoryProvider);
    await repo.saveFreezeState(updated);
    state = AsyncData(updated);
  }
}

final streakFreezeProvider =
    AsyncNotifierProvider<StreakFreezeNotifier, StreakFreezeState>(
  StreakFreezeNotifier.new,
);


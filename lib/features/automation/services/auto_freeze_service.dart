import 'package:uuid/uuid.dart';
import '../../freeze/data/freeze_repository.dart';
import '../../freeze/domain/streak_freeze_state.dart';
import '../../habits/data/habits_repository.dart';
import '../../habits/domain/streak_calculator.dart';
import '../data/automation_repository.dart';
import '../domain/automation_models.dart';

class AutoFreezeService {
  final FreezeRepository _freezeRepository;
  final HabitsRepository _habitsRepository;
  final AutomationRepository _automationRepository;

  AutoFreezeService({
    FreezeRepository? freezeRepository,
    HabitsRepository? habitsRepository,
    AutomationRepository? automationRepository,
  })  : _freezeRepository = freezeRepository ?? LocalFreezeRepository(),
        _habitsRepository = habitsRepository ?? LocalHabitsRepository(),
        _automationRepository = automationRepository ?? LocalAutomationRepository();

  /// Checks if yesterday was missed and automatically applies a Streak Shield
  /// if Smart Auto-Freeze is enabled and shields are available.
  Future<List<String>> evaluateAndApplyAutoFreeze({DateTime? now}) async {
    final settings = await _automationRepository.getSettings();
    if (!settings.isAutoFreezeEnabled) return [];

    final freezeState = await _freezeRepository.getFreezeState();
    if (freezeState.availableFreezes <= 0) return [];

    final currentTime = now ?? DateTime.now();
    final today = StreakCalculator.normalizeDate(currentTime);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayKey = StreakFreezeState.formatDateKey(yesterday);

    // If yesterday is already frozen, nothing to do
    if (freezeState.frozenDates.contains(yesterdayKey)) return [];

    // Check habits: did user complete habits yesterday?
    final habits = await _habitsRepository.getHabits();
    if (habits.isEmpty) return [];

    bool anyHabitCompletedYesterday = false;
    for (final h in habits) {
      final isDone = await _habitsRepository.isCompletedOnDate(h.id, yesterday);
      if (isDone) {
        anyHabitCompletedYesterday = true;
        break;
      }
    }

    // Also check if user had an active streak prior to yesterday
    final dayBeforeYesterday = DateTime(today.year, today.month, today.day - 2);
    bool hadStreakPrior = false;
    for (final h in habits) {
      final streak = await _habitsRepository.calculateStreak(
        h.id,
        dayBeforeYesterday,
        freezeState.frozenDateTimes,
      );
      if (streak > 0) {
        hadStreakPrior = true;
        break;
      }
    }

    // If no habits were completed yesterday and user had an active streak before,
    // auto-freeze yesterday to protect the streak!
    if (!anyHabitCompletedYesterday && hadStreakPrior) {
      final updatedState = freezeState.copyWith(
        availableFreezes: freezeState.availableFreezes - 1,
        frozenDates: [...freezeState.frozenDates, yesterdayKey],
      );

      await _freezeRepository.saveFreezeState(updatedState);

      final event = AutomationEvent(
        id: const Uuid().v4(),
        type: AutomationEventType.autoFreeze,
        title: '🛡️ Smart Shield Activated',
        message: 'Rescued your streak! Missed day ($yesterdayKey) was automatically frozen.',
        timestamp: currentTime,
        metadata: {'frozenDate': yesterdayKey, 'shieldsRemaining': updatedState.availableFreezes},
      );
      await _automationRepository.logEvent(event);

      return [yesterdayKey];
    }

    return [];
  }
}


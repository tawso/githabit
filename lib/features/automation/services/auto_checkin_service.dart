import 'package:uuid/uuid.dart';
import '../../github/domain/github_activity_model.dart';
import '../../habits/data/habits_repository.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/streak_calculator.dart';
import '../data/automation_repository.dart';
import '../domain/automation_models.dart';

class AutoCheckinService {
  final HabitsRepository _habitsRepository;
  final AutomationRepository _automationRepository;

  AutoCheckinService({
    HabitsRepository? habitsRepository,
    AutomationRepository? automationRepository,
  })  : _habitsRepository = habitsRepository ?? LocalHabitsRepository(),
        _automationRepository = automationRepository ?? LocalAutomationRepository();

  /// Evaluates GitHub activity and automatically checks in coding-related habits for today.
  Future<List<String>> evaluateAndApplyAutoCheckin({
    required GithubActivityModel? githubActivity,
    DateTime? now,
  }) async {
    final settings = await _automationRepository.getSettings();
    if (!settings.isAutoCheckinEnabled || githubActivity == null) return [];

    final currentTime = now ?? DateTime.now();
    final today = StreakCalculator.normalizeDate(currentTime);

    // Check if there is GitHub activity today
    final todayContributions = githubActivity.todayContributions;
    final hasRecentCommitsToday = githubActivity.recentCommits.any((c) {
      final commitDate = StreakCalculator.normalizeDate(c.date);
      return commitDate == today;
    });

    final hasActivityToday = todayContributions > 0 || hasRecentCommitsToday;
    if (!hasActivityToday) return [];

    // Find coding/git habits
    final habits = await _habitsRepository.getHabits();
    final checkedInTitles = <String>[];

    for (final habit in habits) {
      final isCodingHabit = habit.category == HabitCategory.coding ||
          _isCodingOrGitKeyword(habit.title) ||
          _isCodingOrGitKeyword(habit.description ?? '');

      if (!isCodingHabit) continue;

      final isAlreadyDone = await _habitsRepository.isCompletedOnDate(habit.id, today);
      if (!isAlreadyDone) {
        await _habitsRepository.toggleCheckIn(habit.id, today);
        checkedInTitles.add(habit.title);

        final event = AutomationEvent(
          id: const Uuid().v4(),
          type: AutomationEventType.autoCheckin,
          title: '⚡ Auto-Checkin: ${habit.title}',
          message: 'Detected GitHub activity ($todayContributions commits/contributions). Habit checked in automatically!',
          timestamp: currentTime,
          metadata: {
            'habitId': habit.id,
            'habitTitle': habit.title,
            'contributions': todayContributions,
          },
        );
        await _automationRepository.logEvent(event);
      }
    }

    return checkedInTitles;
  }

  static bool _isCodingOrGitKeyword(String text) {
    final lower = text.toLowerCase();
    final keywords = [
      'git',
      'github',
      'commit',
      'code',
      'coding',
      'push',
      'pr',
      'pull request',
      'leetcode',
      'review',
      'dev',
      'программирование',
      'коммит',
      'код',
    ];
    return keywords.any((k) => lower.contains(k));
  }
}


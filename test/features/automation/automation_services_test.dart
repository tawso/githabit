import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:githabit/features/automation/data/automation_repository.dart';
import 'package:githabit/features/automation/domain/automation_models.dart';
import 'package:githabit/features/automation/presentation/automation_provider.dart';
import 'package:githabit/features/automation/presentation/automation_settings_dialog.dart';
import 'package:githabit/features/automation/services/auto_checkin_service.dart';
import 'package:githabit/features/automation/services/auto_freeze_service.dart';
import 'package:githabit/features/automation/services/smart_notification_service.dart';
import 'package:githabit/features/freeze/data/freeze_repository.dart';
import 'package:githabit/features/freeze/domain/streak_freeze_state.dart';
import 'package:githabit/features/github/domain/github_activity_model.dart';
import 'package:githabit/features/habits/data/habits_repository.dart';
import 'package:githabit/features/habits/domain/habit.dart';

// In-memory test repositories
class MockAutomationRepo implements AutomationRepository {
  AutomationSettings settings = const AutomationSettings();
  final List<AutomationEvent> events = [];

  @override
  Future<AutomationSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(AutomationSettings newSettings) async {
    settings = newSettings;
  }

  @override
  Future<List<AutomationEvent>> getRecentEvents({int limit = 15}) async => events;

  @override
  Future<void> logEvent(AutomationEvent event) async {
    events.insert(0, event);
  }
}

class MockFreezeRepo implements FreezeRepository {
  StreakFreezeState state = const StreakFreezeState(availableFreezes: 2, frozenDates: []);

  @override
  Future<StreakFreezeState> getFreezeState() async => state;

  @override
  Future<void> saveFreezeState(StreakFreezeState newState) async {
    state = newState;
  }
}

class MockHabitsRepo implements HabitsRepository {
  final List<Habit> habits = [];
  final Map<String, Set<String>> checkins = {}; // habitId -> set of 'yyyy-MM-dd'

  @override
  Future<List<Habit>> getHabits() async => habits;

  @override
  Future<void> saveHabit(Habit habit) async {
    habits.removeWhere((h) => h.id == habit.id);
    habits.add(habit);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    habits.removeWhere((h) => h.id == habitId);
    checkins.remove(habitId);
  }

  @override
  Future<bool> toggleCheckIn(String habitId, DateTime date) async {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final set = checkins.putIfAbsent(habitId, () => <String>{});
    if (set.contains(key)) {
      set.remove(key);
      return false;
    } else {
      set.add(key);
      return true;
    }
  }

  @override
  Future<bool> isCompletedOnDate(String habitId, DateTime date) async {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return checkins[habitId]?.contains(key) ?? false;
  }

  @override
  Future<int> calculateStreak(String habitId, [DateTime? relativeTo, Iterable<DateTime>? frozenDates]) async {
    return (checkins[habitId]?.isNotEmpty ?? false) ? 3 : 0;
  }

  @override
  Future<int> calculateLongestStreak(String habitId, [Iterable<DateTime>? frozenDates]) async => 5;

  @override
  Future<List<bool>> getLast7DaysStatus(String habitId, [DateTime? relativeTo]) async => List.filled(7, false);

  @override
  Future<List<DateTime>> getCheckInDates(String habitId) async => [];

  @override
  Future<Map<DateTime, int>> getAllHabitsContributionMap() async => {};
}

void main() {
  group('AutoCheckinService Unit Tests', () {
    late MockHabitsRepo habitsRepo;
    late MockAutomationRepo automationRepo;
    late AutoCheckinService service;

    setUp(() {
      habitsRepo = MockHabitsRepo();
      automationRepo = MockAutomationRepo();
      service = AutoCheckinService(
        habitsRepository: habitsRepo,
        automationRepository: automationRepo,
      );
    });

    test('Auto-checks in coding habit when GitHub activity is present today', () async {
      final now = DateTime.now();
      final todayNorm = DateTime(now.year, now.month, now.day);

      habitsRepo.habits.add(
        Habit(
          id: 'h1',
          title: 'Daily Git Commit',
          category: HabitCategory.coding,
          createdAt: now,
        ),
      );

      final githubActivity = GithubActivityModel(
        username: 'alice',
        totalContributions: 5,
        currentStreak: 2,
        longestStreak: 5,
        contributionsMap: {todayNorm: 3},
        lastFetched: now,
      );

      final checkedIn = await service.evaluateAndApplyAutoCheckin(
        githubActivity: githubActivity,
        now: now,
      );

      expect(checkedIn, contains('Daily Git Commit'));
      final isDone = await habitsRepo.isCompletedOnDate('h1', now);
      expect(isDone, isTrue);
      expect(automationRepo.events.length, 1);
      expect(automationRepo.events.first.type, AutomationEventType.autoCheckin);
    });

    test('Does not check in when auto-checkin setting is disabled', () async {
      automationRepo.settings = const AutomationSettings(isAutoCheckinEnabled: false);
      final now = DateTime.now();
      final todayNorm = DateTime(now.year, now.month, now.day);

      habitsRepo.habits.add(
        Habit(
          id: 'h1',
          title: 'Code in Dart',
          category: HabitCategory.coding,
          createdAt: now,
        ),
      );

      final githubActivity = GithubActivityModel(
        username: 'alice',
        totalContributions: 5,
        currentStreak: 2,
        longestStreak: 5,
        contributionsMap: {todayNorm: 3},
        lastFetched: now,
      );

      final checkedIn = await service.evaluateAndApplyAutoCheckin(
        githubActivity: githubActivity,
        now: now,
      );

      expect(checkedIn, isEmpty);
      expect(automationRepo.events, isEmpty);
    });
  });

  group('AutoFreezeService Unit Tests', () {
    late MockFreezeRepo freezeRepo;
    late MockHabitsRepo habitsRepo;
    late MockAutomationRepo automationRepo;
    late AutoFreezeService autoFreezeService;

    setUp(() {
      freezeRepo = MockFreezeRepo();
      habitsRepo = MockHabitsRepo();
      automationRepo = MockAutomationRepo();
      autoFreezeService = AutoFreezeService(
        freezeRepository: freezeRepo,
        habitsRepository: habitsRepo,
        automationRepository: automationRepo,
      );
    });

    test('Auto-freezes yesterday when yesterday was missed and user had streak', () async {
      final now = DateTime(2026, 10, 9, 12, 0);

      habitsRepo.habits.add(
        Habit(
          id: 'h1',
          title: 'Morning Code',
          category: HabitCategory.coding,
          createdAt: DateTime(2026, 10, 1),
        ),
      );
      // Setup prior streak on 2026-10-07
      await habitsRepo.toggleCheckIn('h1', DateTime(2026, 10, 7));

      // Yesterday is 2026-10-08, day before is 2026-10-07
      final frozen = await autoFreezeService.evaluateAndApplyAutoFreeze(now: now);

      expect(frozen, contains('2026-10-08'));
      expect(freezeRepo.state.availableFreezes, 1);
      expect(freezeRepo.state.frozenDates, contains('2026-10-08'));
      expect(automationRepo.events.first.type, AutomationEventType.autoFreeze);
    });

    test('Does not auto-freeze if user has 0 shields left', () async {
      freezeRepo.state = const StreakFreezeState(availableFreezes: 0, frozenDates: []);
      final now = DateTime(2026, 10, 9, 12, 0);

      habitsRepo.habits.add(
        Habit(
          id: 'h1',
          title: 'Morning Code',
          category: HabitCategory.coding,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

      final frozen = await autoFreezeService.evaluateAndApplyAutoFreeze(now: now);
      expect(frozen, isEmpty);
    });
  });

  group('SmartNotificationService Unit Tests', () {
    test('Triggers morning briefing in morning window', () async {
      final repo = MockAutomationRepo();
      final service = SmartNotificationService(repository: repo);

      final morningTime = DateTime(2026, 10, 9, 9, 15);
      final event = await service.evaluateScheduledNotifications(
        currentStreak: 12,
        uncompletedHabitsCount: 3,
        now: morningTime,
      );

      expect(event, isNotNull);
      expect(event!.type, AutomationEventType.morningBriefing);
      expect(repo.events.length, 1);
    });

    test('Triggers evening streak deadline reminder when habits are pending', () async {
      final repo = MockAutomationRepo();
      final service = SmartNotificationService(repository: repo);

      final eveningTime = DateTime(2026, 10, 9, 21, 30);
      final event = await service.evaluateScheduledNotifications(
        currentStreak: 12,
        uncompletedHabitsCount: 2,
        now: eveningTime,
      );

      expect(event, isNotNull);
      expect(event!.type, AutomationEventType.streakWarning);
      expect(repo.events.length, 1);
    });
  });

  group('AutomationSettingsDialog Widget Tests', () {
    testWidgets('renders dialog toggles and actions properly', (tester) async {
      final mockRepo = MockAutomationRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            automationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AutomationSettingsDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Automation Engine'), findsOneWidget);
      expect(find.text('GitHub Auto-Checkin'), findsOneWidget);
      expect(find.text('Smart Streak Shield'), findsOneWidget);
      expect(find.text('Smart Notifications'), findsOneWidget);
      expect(find.text('Run Automation Check Now'), findsOneWidget);
    });
  });
}

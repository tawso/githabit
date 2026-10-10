import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../freeze/presentation/freeze_provider.dart';
import '../../github/presentation/github_provider.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import '../data/automation_repository.dart';
import '../domain/automation_models.dart';
import '../services/auto_checkin_service.dart';
import '../services/auto_freeze_service.dart';
import '../services/smart_notification_service.dart';

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  return LocalAutomationRepository();
});

class AutomationSettingsNotifier extends AsyncNotifier<AutomationSettings> {
  @override
  Future<AutomationSettings> build() async {
    final repo = ref.read(automationRepositoryProvider);
    return repo.getSettings();
  }

  Future<void> toggleAutoCheckin() async {
    final current = state.value ?? const AutomationSettings();
    final updated = current.copyWith(isAutoCheckinEnabled: !current.isAutoCheckinEnabled);
    final repo = ref.read(automationRepositoryProvider);
    await repo.saveSettings(updated);
    state = AsyncData(updated);
  }

  Future<void> toggleAutoFreeze() async {
    final current = state.value ?? const AutomationSettings();
    final updated = current.copyWith(isAutoFreezeEnabled: !current.isAutoFreezeEnabled);
    final repo = ref.read(automationRepositoryProvider);
    await repo.saveSettings(updated);
    state = AsyncData(updated);
  }

  Future<void> toggleSmartNotifications() async {
    final current = state.value ?? const AutomationSettings();
    final updated = current.copyWith(
      isSmartNotificationsEnabled: !current.isSmartNotificationsEnabled,
    );
    final repo = ref.read(automationRepositoryProvider);
    await repo.saveSettings(updated);
    state = AsyncData(updated);
  }
}

final automationSettingsProvider =
    AsyncNotifierProvider<AutomationSettingsNotifier, AutomationSettings>(
  AutomationSettingsNotifier.new,
);

final automationEventsProvider = FutureProvider<List<AutomationEvent>>((ref) async {
  final repo = ref.watch(automationRepositoryProvider);
  return repo.getRecentEvents(limit: 15);
});

/// Coordinator that runs all background automations:
/// 1. Smart Auto-Freeze
/// 2. Auto-Checkin via GitHub Activity
/// 3. Smart Scheduled Notifications
final automationEvaluationProvider = FutureProvider<void>((ref) async {
  final autoFreezeService = AutoFreezeService(
    freezeRepository: ref.read(freezeRepositoryProvider),
    habitsRepository: ref.read(habitsRepositoryProvider),
    automationRepository: ref.read(automationRepositoryProvider),
  );

  final autoCheckinService = AutoCheckinService(
    habitsRepository: ref.read(habitsRepositoryProvider),
    automationRepository: ref.read(automationRepositoryProvider),
  );

  final smartNotificationService = SmartNotificationService(
    repository: ref.read(automationRepositoryProvider),
  );

  // 1. Evaluate Auto-Freeze
  final frozenDates = await autoFreezeService.evaluateAndApplyAutoFreeze();
  if (frozenDates.isNotEmpty) {
    ref.invalidate(streakFreezeProvider);
    ref.invalidate(habitsProvider);
  }

  // 2. Evaluate Auto-Checkin using Github Activity
  final githubActivity = ref.watch(githubActivityProvider).value;
  if (githubActivity != null) {
    final autoCheckedHabits = await autoCheckinService.evaluateAndApplyAutoCheckin(
      githubActivity: githubActivity,
    );
    if (autoCheckedHabits.isNotEmpty) {
      ref.invalidate(habitsProvider);
    }
  }

  // 3. Evaluate Notifications
  final streak = ref.watch(streakProvider).currentStreak;
  final habits = ref.watch(habitsProvider).value ?? [];
  final uncompleted = habits.where((h) => !h.isCompletedToday).length;

  await smartNotificationService.evaluateScheduledNotifications(
    currentStreak: streak,
    uncompletedHabitsCount: uncompleted,
  );

  ref.invalidate(automationEventsProvider);
});


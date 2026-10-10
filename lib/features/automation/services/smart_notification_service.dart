import 'package:uuid/uuid.dart';
import '../data/automation_repository.dart';
import '../domain/automation_models.dart';

class SmartNotificationService {
  final AutomationRepository _repository;

  SmartNotificationService({AutomationRepository? repository})
      : _repository = repository ?? LocalAutomationRepository();

  /// Evaluates and triggers time-based notifications (morning briefing / evening deadline).
  Future<AutomationEvent?> evaluateScheduledNotifications({
    required int currentStreak,
    required int uncompletedHabitsCount,
    DateTime? now,
  }) async {
    final settings = await _repository.getSettings();
    if (!settings.isSmartNotificationsEnabled) return null;

    final currentTime = now ?? DateTime.now();
    final hour = currentTime.hour;
    final dateKey = '${currentTime.year}-${currentTime.month}-${currentTime.day}';

    final recentEvents = await _repository.getRecentEvents(limit: 20);

    // 1. Morning Briefing: between morningBriefingHour and morningBriefingHour + 2
    if (hour >= settings.morningBriefingHour && hour < settings.morningBriefingHour + 2) {
      final alreadySentMorning = recentEvents.any((e) =>
          e.type == AutomationEventType.morningBriefing &&
          e.timestamp.year == currentTime.year &&
          e.timestamp.month == currentTime.month &&
          e.timestamp.day == currentTime.day);

      if (!alreadySentMorning) {
        final event = AutomationEvent(
          id: const Uuid().v4(),
          type: AutomationEventType.morningBriefing,
          title: '🌅 Morning Briefing',
          message: currentStreak > 0
              ? 'Your streak is $currentStreak days! You have $uncompletedHabitsCount habits planned for today.'
              : 'Kick off your developer streak today! $uncompletedHabitsCount habits waiting.',
          timestamp: currentTime,
          metadata: {'date': dateKey, 'streak': currentStreak},
        );
        await _repository.logEvent(event);
        return event;
      }
    }

    // 2. Evening Deadline Reminder: at or after eveningDeadlineHour if habits remain uncompleted
    if (hour >= settings.eveningDeadlineHour && uncompletedHabitsCount > 0) {
      final alreadySentWarning = recentEvents.any((e) =>
          e.type == AutomationEventType.streakWarning &&
          e.timestamp.year == currentTime.year &&
          e.timestamp.month == currentTime.month &&
          e.timestamp.day == currentTime.day);

      if (!alreadySentWarning) {
        final hoursLeft = 24 - hour;
        final event = AutomationEvent(
          id: const Uuid().v4(),
          type: AutomationEventType.streakWarning,
          title: '🔥 Streak Warning ($hoursLeft hrs left)',
          message: 'Don\'t let your streak break! You still have $uncompletedHabitsCount uncompleted habits for today.',
          timestamp: currentTime,
          metadata: {'date': dateKey, 'uncompleted': uncompletedHabitsCount},
        );
        await _repository.logEvent(event);
        return event;
      }
    }

    return null;
  }
}


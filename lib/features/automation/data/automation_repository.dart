import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import '../domain/automation_models.dart';

abstract class AutomationRepository {
  Future<AutomationSettings> getSettings();
  Future<void> saveSettings(AutomationSettings settings);
  Future<List<AutomationEvent>> getRecentEvents({int limit = 15});
  Future<void> logEvent(AutomationEvent event);
}

class LocalAutomationRepository implements AutomationRepository {
  static const _settingsKey = 'githabit_automation_settings';
  static const _eventsKey = 'githabit_automation_events';

  @override
  Future<AutomationSettings> getSettings() async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final raw = DatabaseService.settingsBox.get(_settingsKey);
        if (raw is Map) {
          return AutomationSettings.fromMap(raw);
        }
      }
    } catch (_) {}
    return const AutomationSettings();
  }

  @override
  Future<void> saveSettings(AutomationSettings settings) async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put(_settingsKey, settings.toMap());
      }
    } catch (_) {}
  }

  @override
  Future<List<AutomationEvent>> getRecentEvents({int limit = 15}) async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final raw = DatabaseService.settingsBox.get(_eventsKey);
        if (raw is List) {
          final list = <AutomationEvent>[];
          for (final item in raw) {
            if (item is Map) {
              list.add(AutomationEvent.fromMap(item));
            }
          }
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list.take(limit).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> logEvent(AutomationEvent event) async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final current = await getRecentEvents(limit: 50);
        final updated = [event, ...current];
        await DatabaseService.settingsBox.put(
          _eventsKey,
          updated.take(50).map((e) => e.toMap()).toList(),
        );
      }
    } catch (_) {}
  }
}


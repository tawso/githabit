import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import '../data/wakatime_repository.dart';
import '../domain/wakatime_stats_model.dart';

final wakatimeRepositoryProvider = Provider<WakaTimeRepository>((ref) {
  return WakaTimeRepositoryImpl();
});

class WakaTimeApiKeyNotifier extends Notifier<String> {
  @override
  String build() {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        return (DatabaseService.settingsBox.get('wakatime_api_key', defaultValue: '') as String?) ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<void> setApiKey(String key) async {
    final clean = key.trim();
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put('wakatime_api_key', clean);
      }
    } catch (_) {}
    state = clean;
  }

  Future<void> clearApiKey() async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.delete('wakatime_api_key');
      }
      if (Hive.isBoxOpen(DatabaseService.cacheBoxName)) {
        await DatabaseService.cacheBox.delete('wakatime_stats_cache');
      }
    } catch (_) {}
    state = '';
  }
}

final wakatimeApiKeyProvider =
    NotifierProvider<WakaTimeApiKeyNotifier, String>(WakaTimeApiKeyNotifier.new);

class WakaTimeUsernameNotifier extends Notifier<String> {
  @override
  String build() {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        return (DatabaseService.settingsBox.get('wakatime_username', defaultValue: '') as String?) ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<void> setUsername(String username) async {
    final clean = username.trim();
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put('wakatime_username', clean);
      }
    } catch (_) {}
    state = clean;
  }
}

final wakatimeUsernameProvider =
    NotifierProvider<WakaTimeUsernameNotifier, String>(WakaTimeUsernameNotifier.new);

final wakatimeStatsProvider = FutureProvider<WakaTimeStatsModel>((ref) async {
  final repo = ref.watch(wakatimeRepositoryProvider);
  final apiKey = ref.watch(wakatimeApiKeyProvider);
  final username = ref.watch(wakatimeUsernameProvider);

  return repo.getStats(
    apiKey: apiKey.isNotEmpty ? apiKey : null,
    username: username.isNotEmpty ? username : null,
  );
});


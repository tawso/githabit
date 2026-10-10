import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leetcode_repository.dart';
import '../domain/leetcode_stats_model.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:githabit/core/database/database_service.dart';

final leetCodeRepositoryProvider = Provider<LeetCodeRepository>((ref) {
  return LeetCodeRepositoryImpl();
});

class LeetCodeUsernameNotifier extends Notifier<String> {
  @override
  String build() {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final val = DatabaseService.settingsBox.get('leetcode_username') as String?;
        if (val == 'coder_pulse') {
          DatabaseService.settingsBox.delete('leetcode_username');
          return '';
        }
        return val ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<void> setUsername(String username) async {
    final clean = username.trim();
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put('leetcode_username', clean);
      }
    } catch (_) {}
    state = clean;
  }
}

final leetCodeUsernameProvider =
    NotifierProvider<LeetCodeUsernameNotifier, String>(LeetCodeUsernameNotifier.new);

final leetCodeStatsProvider = FutureProvider<LeetCodeStatsModel>((ref) async {
  final repo = ref.watch(leetCodeRepositoryProvider);
  final username = ref.watch(leetCodeUsernameProvider);
  return repo.getUserStats(username);
});


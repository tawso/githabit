import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/github_repository.dart';
import '../domain/github_activity_model.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:githabit/core/database/database_service.dart';

final githubRepositoryProvider = Provider<GithubRepository>((ref) {
  return GithubRepositoryImpl();
});

class GithubUsernameNotifier extends Notifier<String> {
  @override
  String build() {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final val = DatabaseService.settingsBox.get('github_username') as String?;
        if (val == 'torvalds') {
          DatabaseService.settingsBox.delete('github_username');
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
        await DatabaseService.settingsBox.put('github_username', clean);
      }
    } catch (_) {}
    state = clean;
  }
}

final githubUsernameProvider =
    NotifierProvider<GithubUsernameNotifier, String>(GithubUsernameNotifier.new);

final githubActivityProvider = FutureProvider<GithubActivityModel>((ref) async {
  final repo = ref.watch(githubRepositoryProvider);
  final username = ref.watch(githubUsernameProvider);
  return repo.getUserActivity(username);
});


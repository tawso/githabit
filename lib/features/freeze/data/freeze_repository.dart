import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import '../domain/streak_freeze_state.dart';

abstract class FreezeRepository {
  Future<StreakFreezeState> getFreezeState();
  Future<void> saveFreezeState(StreakFreezeState state);
}

class LocalFreezeRepository implements FreezeRepository {
  static const _storageKey = 'streak_freeze_state';

  @override
  Future<StreakFreezeState> getFreezeState() async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final raw = DatabaseService.settingsBox.get(_storageKey);
        if (raw is Map) {
          return StreakFreezeState.fromMap(raw);
        }
      }
    } catch (_) {}
    return const StreakFreezeState();
  }

  @override
  Future<void> saveFreezeState(StreakFreezeState state) async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put(_storageKey, state.toMap());
      }
    } catch (_) {}
  }
}


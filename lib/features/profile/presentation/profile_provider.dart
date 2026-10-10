import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import '../domain/user_profile.dart';

class ProfileNotifier extends Notifier<UserProfile> {
  static const _profileKey = 'user_profile_data';

  @override
  UserProfile build() {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        final raw = DatabaseService.settingsBox.get(_profileKey);
        if (raw is Map) {
          return UserProfile.fromMap(raw);
        }
      }
    } catch (_) {}
    return const UserProfile();
  }

  Future<void> updateProfile({
    String? name,
    String? role,
    String? company,
    ProfileCardStyle? style,
    bool? isAvailableForHire,
  }) async {
    final updated = state.copyWith(
      name: name,
      role: role,
      company: company,
      style: style,
      isAvailableForHire: isAvailableForHire,
    );
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put(_profileKey, updated.toMap());
      }
    } catch (_) {}
    state = updated;
  }

  Future<void> toggleStyle() async {
    final nextStyle = state.style == ProfileCardStyle.obsidian
        ? ProfileCardStyle.liquidSunset
        : ProfileCardStyle.obsidian;
    await updateProfile(style: nextStyle);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

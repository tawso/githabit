import 'dart:convert';
import 'dart:math';
import 'package:githabit/core/database/database_service.dart';
import 'package:githabit/core/network/dio_client.dart';
import '../domain/leetcode_stats_model.dart';
import 'leetcode_remote_data_source.dart';
import '../../habits/domain/streak_calculator.dart';

abstract class LeetCodeRepository {
  Future<LeetCodeStatsModel> getUserStats(String username, {bool forceRefresh = false});
  LeetCodeStatsModel generateRealisticMock(String username);
}

class LeetCodeRepositoryImpl implements LeetCodeRepository {
  final LeetCodeRemoteDataSource _remoteDataSource;

  LeetCodeRepositoryImpl([LeetCodeRemoteDataSource? remoteDataSource])
      : _remoteDataSource = remoteDataSource ?? LeetCodeRemoteDataSource(DioClient());

  @override
  Future<LeetCodeStatsModel> getUserStats(
    String username, {
    bool forceRefresh = false,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      return LeetCodeStatsModel.empty();
    }

    final cacheKey = 'leetcode_$cleanUsername';

    // 1. Check local cache
    if (!forceRefresh) {
      final cachedJson = DatabaseService.cacheBox.get(cacheKey);
      if (cachedJson != null) {
        try {
          final map = jsonDecode(cachedJson) as Map<dynamic, dynamic>;
          final cachedModel = LeetCodeStatsModel.fromMap(map);
          if (DateTime.now().difference(cachedModel.lastFetched).inHours < 2) {
            return cachedModel;
          }
        } catch (_) {}
      }
    }

    // 2. Attempt remote fetch
    try {
      final result = await _remoteDataSource.fetchUserProfile(cleanUsername);

      // Cache result
      await DatabaseService.cacheBox.put(
        cacheKey,
        jsonEncode(result.toMap()),
      );

      return result;
    } catch (_) {
      // 3. Fallback to cache or empty model
      final cachedJson = DatabaseService.cacheBox.get(cacheKey);
      if (cachedJson != null) {
        try {
          final map = jsonDecode(cachedJson) as Map<dynamic, dynamic>;
          return LeetCodeStatsModel.fromMap(map);
        } catch (_) {}
      }

      return LeetCodeStatsModel.empty(cleanUsername);
    }
  }

  @override
  LeetCodeStatsModel generateRealisticMock(String username) {
    final now = DateTime.now();
    final today = StreakCalculator.normalizeDate(now);
    final random = Random(username.hashCode ^ 1337);

    final Map<DateTime, int> submissionCalendar = {};

    // Generate ~120 days of submissions
    for (int i = 120; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day - i);

      if (i <= 14) {
        // Active 14-day streak
        submissionCalendar[date] = random.nextInt(4) + 1;
      } else {
        if (random.nextDouble() > 0.4) {
          submissionCalendar[date] = random.nextInt(3) + 1;
        }
      }
    }

    final currentStreak = StreakCalculator.calculateCurrentStreak(
      submissionCalendar.keys,
      relativeTo: today,
    );

    return LeetCodeStatsModel(
      username: username,
      totalSolved: 480,
      totalQuestions: 3100,
      easySolved: 165,
      easyTotal: 800,
      mediumSolved: 245,
      mediumTotal: 1600,
      hardSolved: 70,
      hardTotal: 700,
      ranking: 42105,
      acceptanceRate: 72.8,
      currentStreak: currentStreak,
      submissionCalendar: submissionCalendar,
      lastFetched: now,
      isMock: true,
    );
  }
}


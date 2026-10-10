import 'dart:convert';
import 'dart:math';
import 'package:githabit/core/database/database_service.dart';
import 'package:githabit/core/network/dio_client.dart';
import '../domain/github_activity_model.dart';
import 'github_remote_data_source.dart';
import '../../habits/domain/streak_calculator.dart';

abstract class GithubRepository {
  Future<GithubActivityModel> getUserActivity(String username, {bool forceRefresh = false});
  GithubActivityModel generateRealisticMock(String username);
}

class GithubRepositoryImpl implements GithubRepository {
  final GithubRemoteDataSource _remoteDataSource;

  GithubRepositoryImpl([GithubRemoteDataSource? remoteDataSource])
      : _remoteDataSource = remoteDataSource ?? GithubRemoteDataSource(DioClient());

  @override
  Future<GithubActivityModel> getUserActivity(
    String username, {
    bool forceRefresh = false,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      return GithubActivityModel.empty();
    }

    final cacheKey = 'github_$cleanUsername';

    // 1. Check local cache if not force refreshing
    if (!forceRefresh) {
      final cachedJson = DatabaseService.cacheBox.get(cacheKey);
      if (cachedJson != null) {
        try {
          final map = jsonDecode(cachedJson) as Map<dynamic, dynamic>;
          final cachedModel = GithubActivityModel.fromMap(map);
          // If cached less than 1 hour ago, return cache
          if (DateTime.now().difference(cachedModel.lastFetched).inHours < 1) {
            return cachedModel;
          }
        } catch (_) {
          // If cache corrupted, proceed to fetch
        }
      }
    }

    // 2. Attempt remote fetch
    try {
      final token = DatabaseService.cacheBox.get('github_token');
      final result = await _remoteDataSource.fetchUserActivity(cleanUsername, token: token);

      // Save to cache
      await DatabaseService.cacheBox.put(
        cacheKey,
        jsonEncode(result.toMap()),
      );

      return result;
    } catch (_) {
      // 3. Fallback to cached data or empty model
      final cachedJson = DatabaseService.cacheBox.get(cacheKey);
      if (cachedJson != null) {
        try {
          final map = jsonDecode(cachedJson) as Map<dynamic, dynamic>;
          return GithubActivityModel.fromMap(map);
        } catch (_) {}
      }

      return GithubActivityModel.empty(cleanUsername);
    }
  }

  @override
  GithubActivityModel generateRealisticMock(String username) {
    final now = DateTime.now();
    final today = StreakCalculator.normalizeDate(now);
    final random = Random(username.hashCode ^ 42);

    final Map<DateTime, int> contributionMap = {};
    int totalContributions = 0;

    // Generate 140 days of history (~20 weeks)
    for (int i = 140; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day - i);
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      int commits = 0;
      final chance = random.nextDouble();

      // Recent 14 days active for a solid current streak
      if (i <= 14) {
        commits = isWeekend ? (random.nextInt(3) + 1) : (random.nextInt(8) + 2);
      } else {
        if (isWeekend) {
          if (chance > 0.45) commits = random.nextInt(4);
        } else {
          if (chance > 0.15) commits = random.nextInt(9) + 1;
        }
      }

      if (commits > 0) {
        contributionMap[date] = commits;
        totalContributions += commits;
      }
    }

    final currentStreak = StreakCalculator.calculateCurrentStreak(
      contributionMap.keys,
      relativeTo: today,
    );
    final longestStreak = StreakCalculator.calculateLongestStreak(contributionMap.keys);

    final recentCommits = [
      GithubCommitInfo(
        repoName: '$username/GitHabit',
        message: 'feat: add BentoGrid contribution heatmap custom painter',
        date: now.subtract(const Duration(minutes: 42)),
        commitSha: '8f3a9b1',
      ),
      GithubCommitInfo(
        repoName: '$username/GitHabit',
        message: 'fix: eliminate streak timezone drift in calendar calculator',
        date: now.subtract(const Duration(hours: 3)),
        commitSha: 'c2e40a7',
      ),
      GithubCommitInfo(
        repoName: '$username/dotfiles',
        message: 'chore(nvim): update lsp and telescope keymaps',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        commitSha: '419fb8c',
      ),
      GithubCommitInfo(
        repoName: '$username/algo-vault',
        message: 'solve: LC 238 Product of Array Except Self',
        date: now.subtract(const Duration(days: 2)),
        commitSha: 'e91da24',
      ),
    ];

    return GithubActivityModel(
      username: username,
      totalContributions: totalContributions,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      contributionsMap: contributionMap,
      recentCommits: recentCommits,
      lastFetched: now,
      isMock: true,
    );
  }
}


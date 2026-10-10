import 'dart:convert';
import '../../../core/database/database_service.dart';
import '../domain/wakatime_stats_model.dart';
import 'wakatime_remote_data_source.dart';

abstract class WakaTimeRepository {
  Future<WakaTimeStatsModel> getStats({
    String? apiKey,
    String? username,
    bool forceRefresh = false,
  });
  WakaTimeStatsModel generateRealisticMock([String? username]);
}

class WakaTimeRepositoryImpl implements WakaTimeRepository {
  final WakaTimeRemoteDataSource _remoteDataSource;

  WakaTimeRepositoryImpl([WakaTimeRemoteDataSource? remoteDataSource])
      : _remoteDataSource = remoteDataSource ?? WakaTimeRemoteDataSource();

  @override
  Future<WakaTimeStatsModel> getStats({
    String? apiKey,
    String? username,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'wakatime_stats_cache';

    final hasCredentials = (apiKey != null && apiKey.trim().isNotEmpty) ||
        (username != null && username.trim().isNotEmpty);

    // 1. Check local cache if not force refreshing
    if (!forceRefresh) {
      try {
        final cachedJson = DatabaseService.cacheBox.get(cacheKey);
        if (cachedJson != null) {
          final map = jsonDecode(cachedJson) as Map<dynamic, dynamic>;
          final cachedModel = WakaTimeStatsModel.fromMap(map);
          // If cached less than 30 minutes ago, return cache
          if (DateTime.now().difference(cachedModel.lastFetched).inMinutes < 30) {
            return cachedModel;
          }
        }
      } catch (_) {}
    }

    // 2. If credentials provided, fetch remote
    if (hasCredentials) {
      try {
        final result = await _remoteDataSource.fetchUserStats(
          apiKey: apiKey,
          username: username,
        );

        // Save to cache
        await DatabaseService.cacheBox.put(
          cacheKey,
          jsonEncode(result.toMap()),
        );

        return result;
      } catch (_) {
        // Fallback to cache if available
        try {
          final cachedJson = DatabaseService.cacheBox.get(cacheKey);
          if (cachedJson != null) {
            final map = jsonDecode(cachedJson) as Map<dynamic, dynamic>;
            return WakaTimeStatsModel.fromMap(map);
          }
        } catch (_) {}
      }
    }

    // 3. Fallback to empty model if no credentials or offline
    return WakaTimeStatsModel.empty(username);
  }

  @override
  WakaTimeStatsModel generateRealisticMock([String? username]) {
    final now = DateTime.now();

    const languages = [
      LanguageStat(
        name: 'Dart / Flutter',
        percentage: 0.44,
        timeText: '2h 31m',
        colorValue: 0xFF58A6FF,
      ),
      LanguageStat(
        name: 'Rust',
        percentage: 0.26,
        timeText: '1h 28m',
        colorValue: 0xFFFFA116,
      ),
      LanguageStat(
        name: 'TypeScript',
        percentage: 0.18,
        timeText: '1h 02m',
        colorValue: 0xFF388BFD,
      ),
      LanguageStat(
        name: 'Python',
        percentage: 0.12,
        timeText: '41m',
        colorValue: 0xFF39D353,
      ),
    ];

    return WakaTimeStatsModel(
      username: username ?? 'developer',
      humanReadableToday: '5h 42m',
      humanReadableWeek: '34h 15m this week',
      dailyAverage: '4h 53m',
      languages: languages,
      isApiKeyConfigured: false,
      lastFetched: now,
      isMock: true,
    );
  }
}


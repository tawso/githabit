import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/wakatime_stats_model.dart';

class WakaTimeRemoteDataSource {
  final DioClient _dioClient;

  WakaTimeRemoteDataSource([DioClient? dioClient])
      : _dioClient = dioClient ?? DioClient();

  /// Fetches 7-day stats from WakaTime API.
  /// If [apiKey] is present, fetches current user's authenticated stats.
  /// If [username] is provided without key, attempts public stats.
  Future<WakaTimeStatsModel> fetchUserStats({
    String? apiKey,
    String? username,
  }) async {
    final cleanKey = apiKey?.trim();
    final cleanUser = username?.trim();

    String url;
    final Map<String, dynamic> headers = {};
    final Map<String, dynamic> queryParams = {};

    if (cleanKey != null && cleanKey.isNotEmpty) {
      url = 'https://wakatime.com/api/v1/users/current/stats/last_7_days';
      final encodedAuth = base64Encode(utf8.encode(cleanKey));
      headers['Authorization'] = 'Basic $encodedAuth';
      queryParams['api_key'] = cleanKey;
    } else if (cleanUser != null && cleanUser.isNotEmpty) {
      url = 'https://wakatime.com/api/v1/users/$cleanUser/stats/last_7_days';
    } else {
      throw ApiException('No WakaTime API key or username provided.');
    }

    try {
      final response = await _dioClient.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      final humanTotal = data['human_readable_total'] as String? ?? '0h 0m';
      final humanDailyAvg = data['human_readable_daily_average'] as String? ?? '0h 0m';
      final user = data['username'] as String? ?? (cleanUser ?? 'coder');

      final rawLanguages = (data['languages'] as List?) ?? [];
      final List<LanguageStat> languages = [];

      for (final raw in rawLanguages.take(6)) {
        if (raw is Map) {
          final name = raw['name'] as String? ?? 'Other';
          final percent = ((raw['percent'] as num?)?.toDouble() ?? 0.0) / 100.0;
          final text = raw['text'] as String? ?? '0m';

          languages.add(
            LanguageStat(
              name: name,
              percentage: percent,
              timeText: text,
              colorValue: LanguageStat.defaultColorForLanguage(name),
            ),
          );
        }
      }

      // Estimate today's coding time from daily average or primary language
      final todayStr = humanDailyAvg.replaceAll('hrs', 'h').replaceAll('mins', 'm');
      final weekStr = humanTotal.replaceAll('hrs', 'h').replaceAll('mins', 'm');

      return WakaTimeStatsModel(
        username: user,
        humanReadableToday: todayStr,
        humanReadableWeek: '$weekStr this week',
        dailyAverage: humanDailyAvg,
        languages: languages,
        isApiKeyConfigured: cleanKey != null && cleanKey.isNotEmpty,
        lastFetched: DateTime.now(),
        isMock: false,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? e.message ?? 'WakaTime network error',
        statusCode: e.response?.statusCode,
        error: e,
      );
    }
  }
}


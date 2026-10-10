import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:githabit/core/network/dio_client.dart';
import '../domain/leetcode_stats_model.dart';
import '../../habits/domain/streak_calculator.dart';

class LeetCodeRemoteDataSource {
  final DioClient _dioClient;

  LeetCodeRemoteDataSource(this._dioClient);

  Future<LeetCodeStatsModel> fetchUserProfile(String username) async {
    const query = r'''
      query getUserProfile($username: String!) {
        matchedUser(username: $username) {
          username
          submitStatsGlobal {
            acSubmissionNum {
              difficulty
              count
              submissions
            }
          }
          submissionCalendar
          profile {
            ranking
          }
        }
        allQuestionsCount {
          difficulty
          count
        }
      }
    ''';

    try {
      final response = await _dioClient.dio.post(
        'https://leetcode.com/graphql',
        data: {
          'query': query,
          'variables': {'username': username},
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Referer': 'https://leetcode.com',
          },
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null || data['matchedUser'] == null) {
        throw Exception('User $username not found on LeetCode');
      }

      final matchedUser = data['matchedUser'] as Map<String, dynamic>;
      final submitStats =
          matchedUser['submitStatsGlobal']?['acSubmissionNum'] as List<dynamic>? ?? [];

      int easySolved = 0;
      int mediumSolved = 0;
      int hardSolved = 0;
      int totalSolved = 0;

      for (final item in submitStats) {
        if (item is Map) {
          final diff = item['difficulty']?.toString().toLowerCase();
          final count = (item['count'] as num?)?.toInt() ?? 0;
          if (diff == 'all') totalSolved = count;
          if (diff == 'easy') easySolved = count;
          if (diff == 'medium') mediumSolved = count;
          if (diff == 'hard') hardSolved = count;
        }
      }

      // Parse question targets
      final allQuestions = data['allQuestionsCount'] as List<dynamic>? ?? [];
      int easyTotal = 800;
      int mediumTotal = 1600;
      int hardTotal = 700;
      int totalQuestions = 3100;

      for (final item in allQuestions) {
        if (item is Map) {
          final diff = item['difficulty']?.toString().toLowerCase();
          final count = (item['count'] as num?)?.toInt() ?? 0;
          if (diff == 'all') totalQuestions = count;
          if (diff == 'easy') easyTotal = count;
          if (diff == 'medium') mediumTotal = count;
          if (diff == 'hard') hardTotal = count;
        }
      }

      // Parse submissionCalendar
      final calendarRaw = matchedUser['submissionCalendar']?.toString();
      final Map<DateTime, int> submissionMap = {};

      if (calendarRaw != null && calendarRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(calendarRaw) as Map<String, dynamic>;
          decoded.forEach((timestampStr, count) {
            final epochSec = int.tryParse(timestampStr);
            if (epochSec != null) {
              final date = StreakCalculator.normalizeDate(
                DateTime.fromMillisecondsSinceEpoch(epochSec * 1000),
              );
              submissionMap[date] = (count as num).toInt();
            }
          });
        } catch (_) {}
      }

      final ranking = (matchedUser['profile']?['ranking'] as num?)?.toInt();
      final streak = StreakCalculator.calculateCurrentStreak(submissionMap.keys);

      return LeetCodeStatsModel(
        username: username,
        totalSolved: totalSolved > 0 ? totalSolved : (easySolved + mediumSolved + hardSolved),
        totalQuestions: totalQuestions,
        easySolved: easySolved,
        easyTotal: easyTotal,
        mediumSolved: mediumSolved,
        mediumTotal: mediumTotal,
        hardSolved: hardSolved,
        hardTotal: hardTotal,
        ranking: ranking,
        currentStreak: streak,
        submissionCalendar: submissionMap,
        lastFetched: DateTime.now(),
        isMock: false,
      );
    } catch (e) {
      rethrow;
    }
  }
}


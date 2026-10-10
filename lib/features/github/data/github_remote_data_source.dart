import 'package:dio/dio.dart';
import 'package:githabit/core/network/dio_client.dart';
import '../domain/github_activity_model.dart';
import '../../habits/domain/streak_calculator.dart';

class GithubRemoteDataSource {
  final DioClient _dioClient;

  GithubRemoteDataSource(this._dioClient);

  Future<GithubActivityModel> fetchUserActivity(
    String username, {
    String? token,
  }) async {
    // 1. If GitHub Token is provided, use GraphQL to include private commits!
    if (token != null && token.isNotEmpty) {
      try {
        return await _fetchViaGraphQL(username, token);
      } catch (_) {
        // Fallback to public REST events if GraphQL token fails
      }
    }

    // 2. Default: Public REST Events Endpoint
    return _fetchViaRestEvents(username);
  }

  Future<GithubActivityModel> _fetchViaGraphQL(String username, String token) async {
    const query = r'''
      query ($username: String!) {
        user(login: $username) {
          contributionsCollection {
            contributionCalendar {
              totalContributions
              weeks {
                contributionDays {
                  contributionCount
                  date
                }
              }
            }
          }
        }
      }
    ''';

    final response = await _dioClient.dio.post(
      'https://api.github.com/graphql',
      data: {
        'query': query,
        'variables': {'username': username},
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'GitHabit-App',
        },
      ),
    );

    final calendar = response.data['data']?['user']?['contributionsCollection']
        ?['contributionCalendar'] as Map<String, dynamic>?;

    if (calendar == null) {
      throw Exception('Failed to parse GitHub GraphQL calendar');
    }

    final totalCount = (calendar['totalContributions'] as num?)?.toInt() ?? 0;
    final weeks = (calendar['weeks'] as List?) ?? [];
    final Map<DateTime, int> contributionMap = {};

    for (final w in weeks) {
      if (w is Map) {
        final days = (w['contributionDays'] as List?) ?? [];
        for (final d in days) {
          if (d is Map) {
            final dateStr = d['date'] as String?;
            final count = (d['contributionCount'] as num?)?.toInt() ?? 0;
            if (dateStr != null && count > 0) {
              contributionMap[StreakCalculator.normalizeDate(DateTime.parse(dateStr))] =
                  count;
            }
          }
        }
      }
    }

    final streak = StreakCalculator.calculateCurrentStreak(contributionMap.keys);
    final longest = StreakCalculator.calculateLongestStreak(contributionMap.keys);

    return GithubActivityModel(
      username: username,
      totalContributions: totalCount,
      currentStreak: streak,
      longestStreak: longest,
      contributionsMap: contributionMap,
      recentCommits: const [],
      lastFetched: DateTime.now(),
      isMock: false,
    );
  }

  Future<GithubActivityModel> _fetchViaRestEvents(String username) async {
    final response = await _dioClient.dio.get(
      'https://api.github.com/users/$username/events',
      options: Options(
        headers: {
          'User-Agent': 'GitHabit-App',
          'Accept': 'application/vnd.github.v3+json',
        },
      ),
    );

    final List<dynamic> events = response.data is List ? response.data : [];
    final Map<DateTime, int> contributionMap = {};
    final List<GithubCommitInfo> recentCommits = [];
    int totalCount = 0;

    for (final event in events) {
      if (event is! Map) continue;
      final type = event['type'] as String?;
      final createdAtStr = event['created_at'] as String?;
      if (createdAtStr == null) continue;

      final eventDate = StreakCalculator.normalizeDate(DateTime.parse(createdAtStr));
      final repoName = (event['repo'] as Map?)?['name']?.toString() ?? 'unknown-repo';

      if (type == 'PushEvent') {
        final payload = (event['payload'] as Map?) ?? {};
        final commits = (payload['commits'] as List?) ?? [];
        final commitCount = commits.isNotEmpty ? commits.length : 1;

        contributionMap[eventDate] = (contributionMap[eventDate] ?? 0) + commitCount;
        totalCount += commitCount;

        for (final c in commits) {
          if (c is Map && recentCommits.length < 5) {
            recentCommits.add(
              GithubCommitInfo(
                repoName: repoName,
                message: c['message']?.toString().split('\n').first ?? 'Commit',
                date: DateTime.parse(createdAtStr),
                commitSha: c['sha']?.toString().substring(0, 7),
              ),
            );
          }
        }
      } else if (type == 'CreateEvent' ||
          type == 'PullRequestEvent' ||
          type == 'IssuesEvent') {
        contributionMap[eventDate] = (contributionMap[eventDate] ?? 0) + 1;
        totalCount += 1;
      }
    }

    final streak = StreakCalculator.calculateCurrentStreak(contributionMap.keys);
    final longestStreak = StreakCalculator.calculateLongestStreak(contributionMap.keys);

    return GithubActivityModel(
      username: username,
      totalContributions: totalCount,
      currentStreak: streak,
      longestStreak: longestStreak,
      contributionsMap: contributionMap,
      recentCommits: recentCommits,
      lastFetched: DateTime.now(),
      isMock: false,
    );
  }
}

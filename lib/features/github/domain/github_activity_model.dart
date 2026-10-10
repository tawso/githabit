class GithubCommitInfo {
  final String repoName;
  final String message;
  final DateTime date;
  final String? commitSha;

  const GithubCommitInfo({
    required this.repoName,
    required this.message,
    required this.date,
    this.commitSha,
  });

  Map<String, dynamic> toMap() => {
        'repoName': repoName,
        'message': message,
        'date': date.toIso8601String(),
        'commitSha': commitSha,
      };

  factory GithubCommitInfo.fromMap(Map<dynamic, dynamic> map) =>
      GithubCommitInfo(
        repoName: map['repoName'] as String,
        message: map['message'] as String,
        date: DateTime.parse(map['date'] as String),
        commitSha: map['commitSha'] as String?,
      );
}

class GithubActivityModel {
  final String username;
  final int totalContributions;
  final int currentStreak;
  final int longestStreak;
  final Map<DateTime, int> contributionsMap;
  final List<GithubCommitInfo> recentCommits;
  final DateTime lastFetched;
  final bool isMock;

  const GithubActivityModel({
    required this.username,
    required this.totalContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.contributionsMap,
    this.recentCommits = const [],
    required this.lastFetched,
    this.isMock = false,
  });

  int get todayContributions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return contributionsMap[today] ?? 0;
  }

  factory GithubActivityModel.empty([String username = '']) {
    return GithubActivityModel(
      username: username,
      totalContributions: 0,
      currentStreak: 0,
      longestStreak: 0,
      contributionsMap: const {},
      recentCommits: const [],
      lastFetched: DateTime.now(),
      isMock: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'totalContributions': totalContributions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'contributionsMap': contributionsMap.map(
        (key, value) => MapEntry(key.toIso8601String(), value),
      ),
      'recentCommits': recentCommits.map((c) => c.toMap()).toList(),
      'lastFetched': lastFetched.toIso8601String(),
      'isMock': isMock,
    };
  }

  factory GithubActivityModel.fromMap(Map<dynamic, dynamic> map) {
    final rawMap = (map['contributionsMap'] as Map?) ?? {};
    final Map<DateTime, int> parsedMap = {};
    rawMap.forEach((key, value) {
      parsedMap[DateTime.parse(key.toString())] = (value as num).toInt();
    });

    final rawCommits = (map['recentCommits'] as List?) ?? [];
    final commits = rawCommits
        .map((c) => GithubCommitInfo.fromMap(c as Map))
        .toList();

    return GithubActivityModel(
      username: map['username'] as String,
      totalContributions: (map['totalContributions'] as int?) ?? 0,
      currentStreak: (map['currentStreak'] as int?) ?? 0,
      longestStreak: (map['longestStreak'] as int?) ?? 0,
      contributionsMap: parsedMap,
      recentCommits: commits,
      lastFetched: DateTime.parse(map['lastFetched'] as String),
      isMock: (map['isMock'] as bool?) ?? false,
    );
  }
}


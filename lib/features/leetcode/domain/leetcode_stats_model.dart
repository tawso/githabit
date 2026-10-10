class LeetCodeStatsModel {
  final String username;
  final int totalSolved;
  final int totalQuestions;
  final int easySolved;
  final int easyTotal;
  final int mediumSolved;
  final int mediumTotal;
  final int hardSolved;
  final int hardTotal;
  final int? ranking;
  final double acceptanceRate;
  final int currentStreak;
  final Map<DateTime, int> submissionCalendar;
  final DateTime lastFetched;
  final bool isMock;

  const LeetCodeStatsModel({
    required this.username,
    required this.totalSolved,
    this.totalQuestions = 3100,
    required this.easySolved,
    this.easyTotal = 800,
    required this.mediumSolved,
    this.mediumTotal = 1600,
    required this.hardSolved,
    this.hardTotal = 700,
    this.ranking,
    this.acceptanceRate = 68.4,
    required this.currentStreak,
    required this.submissionCalendar,
    required this.lastFetched,
    this.isMock = false,
  });

  factory LeetCodeStatsModel.empty([String username = '']) {
    return LeetCodeStatsModel(
      username: username,
      totalSolved: 0,
      totalQuestions: 3100,
      easySolved: 0,
      easyTotal: 800,
      mediumSolved: 0,
      mediumTotal: 1600,
      hardSolved: 0,
      hardTotal: 700,
      ranking: null,
      acceptanceRate: 0.0,
      currentStreak: 0,
      submissionCalendar: const {},
      lastFetched: DateTime.now(),
      isMock: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'totalSolved': totalSolved,
      'totalQuestions': totalQuestions,
      'easySolved': easySolved,
      'easyTotal': easyTotal,
      'mediumSolved': mediumSolved,
      'mediumTotal': mediumTotal,
      'hardSolved': hardSolved,
      'hardTotal': hardTotal,
      'ranking': ranking,
      'acceptanceRate': acceptanceRate,
      'currentStreak': currentStreak,
      'submissionCalendar': submissionCalendar.map(
        (k, v) => MapEntry(k.toIso8601String(), v),
      ),
      'lastFetched': lastFetched.toIso8601String(),
      'isMock': isMock,
    };
  }

  factory LeetCodeStatsModel.fromMap(Map<dynamic, dynamic> map) {
    final rawCalendar = (map['submissionCalendar'] as Map?) ?? {};
    final Map<DateTime, int> parsedCalendar = {};
    rawCalendar.forEach((k, v) {
      parsedCalendar[DateTime.parse(k.toString())] = (v as num).toInt();
    });

    return LeetCodeStatsModel(
      username: map['username'] as String,
      totalSolved: (map['totalSolved'] as int?) ?? 0,
      totalQuestions: (map['totalQuestions'] as int?) ?? 3100,
      easySolved: (map['easySolved'] as int?) ?? 0,
      easyTotal: (map['easyTotal'] as int?) ?? 800,
      mediumSolved: (map['mediumSolved'] as int?) ?? 0,
      mediumTotal: (map['mediumTotal'] as int?) ?? 1600,
      hardSolved: (map['hardSolved'] as int?) ?? 0,
      hardTotal: (map['hardTotal'] as int?) ?? 700,
      ranking: map['ranking'] as int?,
      acceptanceRate: (map['acceptanceRate'] as num?)?.toDouble() ?? 0.0,
      currentStreak: (map['currentStreak'] as int?) ?? 0,
      submissionCalendar: parsedCalendar,
      lastFetched: DateTime.parse(map['lastFetched'] as String),
      isMock: (map['isMock'] as bool?) ?? false,
    );
  }
}


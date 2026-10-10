import 'package:flutter/material.dart';

class LanguageStat {
  final String name;
  final double percentage;
  final String timeText;
  final int colorValue;

  const LanguageStat({
    required this.name,
    required this.percentage,
    required this.timeText,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
        'name': name,
        'percentage': percentage,
        'timeText': timeText,
        'colorValue': colorValue,
      };

  factory LanguageStat.fromMap(Map<dynamic, dynamic> map) {
    return LanguageStat(
      name: map['name'] as String? ?? 'Other',
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      timeText: map['timeText'] as String? ?? '0m',
      colorValue: (map['colorValue'] as int?) ?? defaultColorForLanguage(map['name'] as String? ?? ''),
    );
  }

  static int defaultColorForLanguage(String lang) {
    final lower = lang.toLowerCase();
    if (lower.contains('dart') || lower.contains('flutter')) return 0xFF58A6FF;
    if (lower.contains('rust')) return 0xFFFFA116;
    if (lower.contains('typescript') || lower.contains('ts')) return 0xFF388BFD;
    if (lower.contains('javascript') || lower.contains('js')) return 0xFFF1E05A;
    if (lower.contains('python')) return 0xFF39D353;
    if (lower.contains('go') || lower.contains('golang')) return 0xFF00ACD7;
    if (lower.contains('kotlin')) return 0xFFA97BFF;
    if (lower.contains('swift')) return 0xFFF05138;
    if (lower.contains('c++') || lower.contains('cpp')) return 0xFFF34B7D;
    if (lower.contains('c#') || lower.contains('csharp')) return 0xFF178600;
    if (lower.contains('html') || lower.contains('css')) return 0xFFE34C26;
    if (lower.contains('sql')) return 0xFFE38C00;
    return 0xFF8B949E;
  }
}

class WakaTimeStatsModel {
  final String username;
  final String humanReadableToday;
  final String humanReadableWeek;
  final String dailyAverage;
  final List<LanguageStat> languages;
  final bool isApiKeyConfigured;
  final DateTime lastFetched;
  final bool isMock;

  const WakaTimeStatsModel({
    required this.username,
    required this.humanReadableToday,
    required this.humanReadableWeek,
    required this.dailyAverage,
    required this.languages,
    this.isApiKeyConfigured = false,
    required this.lastFetched,
    this.isMock = false,
  });

  factory WakaTimeStatsModel.empty([String? username]) {
    return WakaTimeStatsModel(
      username: username ?? '',
      humanReadableToday: '0m',
      humanReadableWeek: '0m this week',
      dailyAverage: '0m',
      languages: const [],
      isApiKeyConfigured: false,
      lastFetched: DateTime.now(),
      isMock: false,
    );
  }

  Map<String, dynamic> toMap() => {
        'username': username,
        'humanReadableToday': humanReadableToday,
        'humanReadableWeek': humanReadableWeek,
        'dailyAverage': dailyAverage,
        'languages': languages.map((l) => l.toMap()).toList(),
        'isApiKeyConfigured': isApiKeyConfigured,
        'lastFetched': lastFetched.toIso8601String(),
        'isMock': isMock,
      };

  factory WakaTimeStatsModel.fromMap(Map<dynamic, dynamic> map) {
    final rawLangs = (map['languages'] as List?) ?? [];
    final langs = rawLangs
        .map((l) => LanguageStat.fromMap(l as Map))
        .toList();

    return WakaTimeStatsModel(
      username: map['username'] as String? ?? 'developer',
      humanReadableToday: map['humanReadableToday'] as String? ?? '0m',
      humanReadableWeek: map['humanReadableWeek'] as String? ?? '0m',
      dailyAverage: map['dailyAverage'] as String? ?? '0m',
      languages: langs,
      isApiKeyConfigured: (map['isApiKeyConfigured'] as bool?) ?? false,
      lastFetched: DateTime.tryParse(map['lastFetched'] as String? ?? '') ?? DateTime.now(),
      isMock: (map['isMock'] as bool?) ?? false,
    );
  }
}


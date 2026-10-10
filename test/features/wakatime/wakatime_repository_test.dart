import 'package:flutter_test/flutter_test.dart';
import 'package:githabit/features/wakatime/data/wakatime_repository.dart';
import 'package:githabit/features/wakatime/domain/wakatime_stats_model.dart';

void main() {
  group('WakaTime Stats Model & Repository Tests', () {
    test('serializes and deserializes WakaTimeStatsModel properly', () {
      final now = DateTime(2026, 10, 9);
      final model = WakaTimeStatsModel(
        username: 'test_dev',
        humanReadableToday: '3h 45m',
        humanReadableWeek: '28h 10m this week',
        dailyAverage: '4h 01m',
        languages: const [
          LanguageStat(
            name: 'Dart',
            percentage: 0.60,
            timeText: '2h 15m',
            colorValue: 0xFF58A6FF,
          ),
          LanguageStat(
            name: 'Rust',
            percentage: 0.40,
            timeText: '1h 30m',
            colorValue: 0xFFFFA116,
          ),
        ],
        isApiKeyConfigured: true,
        lastFetched: now,
        isMock: false,
      );

      final map = model.toMap();
      final restored = WakaTimeStatsModel.fromMap(map);

      expect(restored.username, 'test_dev');
      expect(restored.humanReadableToday, '3h 45m');
      expect(restored.humanReadableWeek, '28h 10m this week');
      expect(restored.isApiKeyConfigured, true);
      expect(restored.languages.length, 2);
      expect(restored.languages.first.name, 'Dart');
      expect(restored.languages.first.percentage, 0.60);
    });

    test('generateRealisticMock produces realistic developer language stats', () {
      final repo = WakaTimeRepositoryImpl();
      final mock = repo.generateRealisticMock('rad1x');

      expect(mock.username, 'rad1x');
      expect(mock.isMock, true);
      expect(mock.isApiKeyConfigured, false);
      expect(mock.languages.isNotEmpty, true);
      expect(mock.languages.any((l) => l.name.contains('Dart')), true);
      expect(mock.languages.any((l) => l.name.contains('Rust')), true);
    });

    test('correctly maps default colors for programming languages', () {
      expect(LanguageStat.defaultColorForLanguage('Dart'), 0xFF58A6FF);
      expect(LanguageStat.defaultColorForLanguage('Rust'), 0xFFFFA116);
      expect(LanguageStat.defaultColorForLanguage('TypeScript'), 0xFF388BFD);
      expect(LanguageStat.defaultColorForLanguage('Python'), 0xFF39D353);
    });
  });
}


import '../../habits/domain/streak_calculator.dart';

class StreakFreezeState {
  final int availableFreezes;
  final List<String> frozenDates; // formatted 'yyyy-MM-dd'

  const StreakFreezeState({
    this.availableFreezes = 2,
    this.frozenDates = const [],
  });

  bool isDateFrozen(DateTime date) {
    final key = formatDateKey(date);
    return frozenDates.contains(key);
  }

  static String formatDateKey(DateTime dt) {
    final norm = StreakCalculator.normalizeDate(dt);
    final y = norm.year.toString().padLeft(4, '0');
    final m = norm.month.toString().padLeft(2, '0');
    final d = norm.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<DateTime> get frozenDateTimes {
    final List<DateTime> result = [];
    for (final s in frozenDates) {
      try {
        result.add(DateTime.parse(s));
      } catch (_) {}
    }
    return result;
  }

  StreakFreezeState copyWith({
    int? availableFreezes,
    List<String>? frozenDates,
  }) {
    return StreakFreezeState(
      availableFreezes: availableFreezes ?? this.availableFreezes,
      frozenDates: frozenDates ?? this.frozenDates,
    );
  }

  Map<String, dynamic> toMap() => {
        'availableFreezes': availableFreezes,
        'frozenDates': frozenDates,
      };

  factory StreakFreezeState.fromMap(Map<dynamic, dynamic> map) {
    final rawDates = map['frozenDates'];
    final List<String> datesList = [];
    if (rawDates is Iterable) {
      for (final item in rawDates) {
        if (item != null) datesList.add(item.toString());
      }
    }
    return StreakFreezeState(
      availableFreezes: (map['availableFreezes'] as int?) ?? 2,
      frozenDates: datesList,
    );
  }
}


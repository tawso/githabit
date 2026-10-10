/// Record of a completed habit check-in on a specific calendar day.
class HabitCheckIn {
  final String id;
  final String habitId;
  final DateTime date; // Normalized YYYY-MM-DD
  final DateTime completedAt;

  const HabitCheckIn({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completedAt,
  });

  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': normalizeDate(date).toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory HabitCheckIn.fromMap(Map<dynamic, dynamic> map) {
    return HabitCheckIn(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      date: normalizeDate(DateTime.parse(map['date'] as String)),
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }
}


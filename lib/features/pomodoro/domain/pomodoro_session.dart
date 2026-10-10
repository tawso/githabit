class PomodoroSession {
  final String id;
  final int durationMinutes;
  final DateTime completedAt;
  final String tag;

  const PomodoroSession({
    required this.id,
    required this.durationMinutes,
    required this.completedAt,
    this.tag = 'General',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'durationMinutes': durationMinutes,
        'completedAt': completedAt.toIso8601String(),
        'tag': tag,
      };

  factory PomodoroSession.fromMap(Map<dynamic, dynamic> map) => PomodoroSession(
        id: map['id'] as String,
        durationMinutes: (map['durationMinutes'] as num).toInt(),
        completedAt: DateTime.parse(map['completedAt'] as String),
        tag: (map['tag'] as String?) ?? 'General',
      );
}


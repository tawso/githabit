enum AutomationEventType {
  autoCheckin,
  autoFreeze,
  streakWarning,
  morningBriefing,
  milestone,
}

class AutomationEvent {
  final String id;
  final AutomationEventType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AutomationEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory AutomationEvent.fromMap(Map<dynamic, dynamic> map) {
    return AutomationEvent(
      id: (map['id'] as String?) ?? '',
      type: AutomationEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AutomationEventType.autoCheckin,
      ),
      title: (map['title'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }
}

class AutomationSettings {
  final bool isAutoCheckinEnabled;
  final bool isAutoFreezeEnabled;
  final bool isSmartNotificationsEnabled;
  final int morningBriefingHour;
  final int eveningDeadlineHour;

  const AutomationSettings({
    this.isAutoCheckinEnabled = true,
    this.isAutoFreezeEnabled = true,
    this.isSmartNotificationsEnabled = true,
    this.morningBriefingHour = 9,
    this.eveningDeadlineHour = 21,
  });

  AutomationSettings copyWith({
    bool? isAutoCheckinEnabled,
    bool? isAutoFreezeEnabled,
    bool? isSmartNotificationsEnabled,
    int? morningBriefingHour,
    int? eveningDeadlineHour,
  }) {
    return AutomationSettings(
      isAutoCheckinEnabled: isAutoCheckinEnabled ?? this.isAutoCheckinEnabled,
      isAutoFreezeEnabled: isAutoFreezeEnabled ?? this.isAutoFreezeEnabled,
      isSmartNotificationsEnabled:
          isSmartNotificationsEnabled ?? this.isSmartNotificationsEnabled,
      morningBriefingHour: morningBriefingHour ?? this.morningBriefingHour,
      eveningDeadlineHour: eveningDeadlineHour ?? this.eveningDeadlineHour,
    );
  }

  Map<String, dynamic> toMap() => {
        'isAutoCheckinEnabled': isAutoCheckinEnabled,
        'isAutoFreezeEnabled': isAutoFreezeEnabled,
        'isSmartNotificationsEnabled': isSmartNotificationsEnabled,
        'morningBriefingHour': morningBriefingHour,
        'eveningDeadlineHour': eveningDeadlineHour,
      };

  factory AutomationSettings.fromMap(Map<dynamic, dynamic> map) {
    return AutomationSettings(
      isAutoCheckinEnabled: (map['isAutoCheckinEnabled'] as bool?) ?? true,
      isAutoFreezeEnabled: (map['isAutoFreezeEnabled'] as bool?) ?? true,
      isSmartNotificationsEnabled:
          (map['isSmartNotificationsEnabled'] as bool?) ?? true,
      morningBriefingHour: (map['morningBriefingHour'] as int?) ?? 9,
      eveningDeadlineHour: (map['eveningDeadlineHour'] as int?) ?? 21,
    );
  }
}


import 'package:flutter/material.dart';

enum HabitCategory {
  coding('Coding', Icons.code, 0xFF388BFD),
  algorithm('LeetCode / DSA', Icons.psychology, 0xFF00B8A3),
  reading('Reading Docs', Icons.menu_book, 0xFFBC8CFF),
  fitness('Dev Health / Gym', Icons.fitness_center, 0xFF39D353),
  devops('Cloud / Open Source', Icons.cloud_done, 0xFFFFA116),
  custom('General Habit', Icons.check_circle_outline, 0xFF58A6FF);

  final String label;
  final IconData icon;
  final int defaultColorValue;

  const HabitCategory(this.label, this.icon, this.defaultColorValue);

  Color get color => Color(defaultColorValue);

  static HabitCategory fromString(String? name) {
    return HabitCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == name?.toLowerCase(),
      orElse: () => HabitCategory.coding,
    );
  }
}

class Habit {
  final String id;
  final String title;
  final String? description;
  final HabitCategory category;
  final int? colorValue;
  final DateTime createdAt;
  final int targetDaysPerWeek;
  final bool isArchived;

  Habit({
    required this.id,
    required this.title,
    this.description,
    this.category = HabitCategory.coding,
    this.colorValue,
    required this.createdAt,
    this.targetDaysPerWeek = 7,
    this.isArchived = false,
  });

  int get effectiveColorValue => colorValue ?? category.defaultColorValue;
  Color get color => Color(effectiveColorValue);

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    int? colorValue,
    DateTime? createdAt,
    int? targetDaysPerWeek,
    bool? isArchived,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'colorValue': effectiveColorValue,
      'createdAt': createdAt.toIso8601String(),
      'targetDaysPerWeek': targetDaysPerWeek,
      'isArchived': isArchived,
    };
  }

  factory Habit.fromMap(Map<dynamic, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: HabitCategory.fromString(map['category'] as String?),
      colorValue: map['colorValue'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      targetDaysPerWeek: (map['targetDaysPerWeek'] as int?) ?? 7,
      isArchived: (map['isArchived'] as bool?) ?? false,
    );
  }
}


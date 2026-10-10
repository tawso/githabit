import 'package:flutter/material.dart';

class DevBadge {
  final String id;
  final String title;
  final String description;
  final String shortCode;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final String dateEarned;
  final double progress; // 0.0 to 1.0
  final String progressLabel;

  const DevBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.shortCode,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.dateEarned,
    this.progress = 0.0,
    this.progressLabel = '',
  });
}


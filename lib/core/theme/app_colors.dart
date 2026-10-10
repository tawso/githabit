import 'package:flutter/material.dart';

/// App color palette matching the strict dark mode specification.
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color scaffoldBackground = Color(0xFF0D0F14);
  static const Color cardSurface = Color(0xFF161B22);
  static const Color cardSurfaceLight = Color(0xFF1F242C);
  static const Color cardSurfaceHover = Color(0xFF262C36);
  static const Color cardBorder = Color(0xFF30363D);

  // Brand / Accents
  static const Color accentPrimary = Color(0xFF388BFD); // Electric Blue
  static const Color accentCyan = Color(0xFF58A6FF);
  static const Color accentPurple = Color(0xFFBC8CFF);

  // Text colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // GitHub Contribution Green 5-level scale
  static const Color githubLevel0 = Color(0xFF21262D);
  static const Color githubLevel1 = Color(0xFF0E4429);
  static const Color githubLevel2 = Color(0xFF006D32);
  static const Color githubLevel3 = Color(0xFF26A641);
  static const Color githubLevel4 = Color(0xFF39D353);

  static const List<Color> githubScale = [
    githubLevel0,
    githubLevel1,
    githubLevel2,
    githubLevel3,
    githubLevel4,
  ];

  // LeetCode Difficulty Palette
  static const Color leetCodeEasy = Color(0xFF00B8A3);
  static const Color leetCodeMedium = Color(0xFFFFA116);
  static const Color leetCodeHard = Color(0xFFFF375F);

  // Habit category colors & Status
  static const Color fireStreak = Color(0xFFFF5722);
  static const Color success = Color(0xFF39D353);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
}


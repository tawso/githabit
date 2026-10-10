import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../github/presentation/github_provider.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import '../../leetcode/presentation/leetcode_provider.dart';
import '../../pomodoro/presentation/pomodoro_provider.dart';
import '../domain/dev_badge.dart';

final badgesProvider = Provider<List<DevBadge>>((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final streakMetrics = ref.watch(streakProvider);
  final ghActivity = ref.watch(githubActivityProvider).value;
  final lcStats = ref.watch(leetCodeStatsProvider).value;
  final pomodoro = ref.watch(pomodoroProvider).value;

  // Compute metrics
  final maxHabitStreak = math.max(streakMetrics.currentStreak, streakMetrics.longestStreak);

  final ghContributions = ghActivity?.totalContributions ?? 0;
  final lcMedHard = (lcStats?.mediumSolved ?? 0) + (lcStats?.hardSolved ?? 0);
  final completedPomodoros = pomodoro?.totalSessions ?? 0;

  final hasNightCheckIn = habits.any((h) => h.checkInDates.any((d) => d.hour < 5 || d.hour >= 23));

  return [
    // 1. 50 Days Streak
    DevBadge(
      id: 'streak_50',
      title: '50 Days Streak',
      description: 'Maintain an active developer streak of at least 50 days.',
      shortCode: '50 DAYS',
      icon: Icons.local_fire_department,
      color: AppColors.fireStreak,
      isUnlocked: maxHabitStreak >= 50,
      dateEarned: maxHabitStreak >= 50 ? 'Unlocked' : 'In Progress ($maxHabitStreak/50)',
      progress: (maxHabitStreak / 50).clamp(0.0, 1.0),
      progressLabel: '$maxHabitStreak / 50 days',
    ),

    // 2. Algorithm Knight
    DevBadge(
      id: 'algo_master',
      title: 'Algorithm Knight',
      description: 'Solve over 50 Medium and Hard algorithm challenges on LeetCode.',
      shortCode: 'ALGO',
      icon: Icons.psychology,
      color: AppColors.leetCodeMedium,
      isUnlocked: lcMedHard >= 50,
      dateEarned: lcMedHard >= 50 ? 'Unlocked' : 'In Progress ($lcMedHard/50)',
      progress: (lcMedHard / 50).clamp(0.0, 1.0),
      progressLabel: '$lcMedHard / 50 solved',
    ),

    // 3. Push Machine
    DevBadge(
      id: 'commit_spree',
      title: 'Push Machine',
      description: 'Record more than 100 GitHub contributions this year.',
      shortCode: 'GIT 100',
      icon: Icons.commit_rounded,
      color: AppColors.accentPrimary,
      isUnlocked: ghContributions >= 100,
      dateEarned: ghContributions >= 100 ? 'Unlocked' : 'In Progress ($ghContributions/100)',
      progress: (ghContributions / 100).clamp(0.0, 1.0),
      progressLabel: '$ghContributions / 100 commits',
    ),

    // 4. Deep Work Master
    DevBadge(
      id: 'pomodoro_master',
      title: 'Deep Work Master',
      description: 'Complete 5 or more focused Pomodoro sessions.',
      shortCode: 'FOCUS',
      icon: Icons.timer_outlined,
      color: AppColors.accentCyan,
      isUnlocked: completedPomodoros >= 5,
      dateEarned: completedPomodoros >= 5 ? 'Unlocked' : 'In Progress ($completedPomodoros/5)',
      progress: (completedPomodoros / 5).clamp(0.0, 1.0),
      progressLabel: '$completedPomodoros / 5 sessions',
    ),

    // 5. Night Owl Coder
    DevBadge(
      id: 'night_owl',
      title: 'Night Owl Coder',
      description: 'Complete development sessions or check-ins past midnight.',
      shortCode: '02 AM',
      icon: Icons.bedtime_rounded,
      color: AppColors.accentPurple,
      isUnlocked: hasNightCheckIn,
      dateEarned: hasNightCheckIn ? 'Unlocked' : 'Locked',
      progress: hasNightCheckIn ? 1.0 : 0.0,
      progressLabel: hasNightCheckIn ? 'Active' : 'Locked',
    ),

    // 6. Century Club 100d
    DevBadge(
      id: 'century_club',
      title: 'Century Streak 100d',
      description: 'Reach an unbroken 100-day developer habit streak.',
      shortCode: '100 DAYS',
      icon: Icons.military_tech_rounded,
      color: AppColors.warning,
      isUnlocked: maxHabitStreak >= 100,
      dateEarned: maxHabitStreak >= 100 ? 'Unlocked' : 'In Progress ($maxHabitStreak/100)',
      progress: (maxHabitStreak / 100).clamp(0.0, 1.0),
      progressLabel: '$maxHabitStreak / 100 days',
    ),
  ];
});

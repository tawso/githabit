import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../automation/presentation/automation_provider.dart';
import '../../automation/presentation/automation_settings_dialog.dart';
import '../../freeze/presentation/freeze_provider.dart';
import '../../freeze/presentation/streak_freeze_dialog.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import '../../profile/widgets/share_dev_card_dialog.dart';
import 'day_streak_card.dart';

/// Modal bottom sheet displaying the interactive Day Streak, 7-day tracker,
/// streak statistics, and fast habit check-ins.
/// Modeled after QuickToolboxSheet to feel tactile and native.
class DayStreakSheet extends ConsumerWidget {
  final VoidCallback? onAddHabit;

  const DayStreakSheet({
    super.key,
    this.onAddHabit,
  });

  /// Opens the DayStreakSheet as a floating Liquid Glass bottom sheet
  static Future<void> show(BuildContext context, {VoidCallback? onAddHabit}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DayStreakSheet(onAddHabit: onAddHabit),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakMetrics = ref.watch(streakProvider);
    final habits = ref.watch(habitsProvider).value ?? [];
    final freezeState = ref.watch(streakFreezeProvider).value;
    final availableFreezes = freezeState?.availableFreezes ?? 0;
    final allDone = streakMetrics.isGoalAchievedToday;
    ref.watch(automationEvaluationProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: LiquidGlassContainer(
          borderRadius: 32,
          blurSigma: 30,
          backgroundColor: const Color(0xE6141820), // 90% opaque frosted slate
          borderColor: const Color(0x38FFFFFF),
          borderWidth: 1.2,
          shadows: [
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Pull indicator handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Title Header with Flame & Close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer Streak & Habits',
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            streakMetrics.currentStreak > 0
                                ? '${streakMetrics.currentStreak} consecutive days of momentum'
                                : 'Start your streak today',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Embedded Animated DayStreakCard
                const DayStreakCard(),
                const SizedBox(height: 14),

                // 4. Quick Streak Stats Bento Pills
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatPill(
                        icon: '🔥',
                        title: 'Current',
                        value: '${streakMetrics.currentStreak}d',
                        accentColor: const Color(0xFFFF8B3D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStatPill(
                        icon: '⚡',
                        title: 'Best',
                        value: '${streakMetrics.longestStreak}d',
                        accentColor: AppColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStatPill(
                        icon: '🎯',
                        title: 'Goal',
                        value: '${streakMetrics.completedToday}/${streakMetrics.totalHabits}',
                        accentColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStatPill(
                        icon: '❄️',
                        title: 'Shields',
                        value: '$availableFreezes',
                        accentColor: const Color(0xFF38BDF8),
                        onTap: () {
                          Navigator.pop(context);
                          StreakFreezeDialog.show(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Smart Automations & Shields Status Bar
                _buildAutomationStatusBar(context, ref),
                const SizedBox(height: 14),

                // 5. Today's Habits Checklist inside Modal
                if (habits.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TODAY'S HABITS",
                        style: AppTypography.monoMicro.copyWith(
                          color: const Color(0xFF8B949E),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${streakMetrics.completedToday}/${streakMetrics.totalHabits} Completed',
                        style: AppTypography.monoMicro.copyWith(
                          color: allDone ? AppColors.success : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurfaceLight.withAlpha(120),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder, width: 0.8),
                    ),
                    child: Column(
                      children: habits.map((item) {
                        final isDone = item.isCompletedToday;
                        return InkWell(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await ref.read(habitsProvider.notifier).toggleCheckIn(item.habit.id);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                // Category Icon
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: item.habit.color.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.habit.category.icon,
                                    size: 15,
                                    color: item.habit.color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title & Streak
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.habit.title,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                          color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '🔥 ${item.streak}d streak',
                                        style: AppTypography.monoMicro.copyWith(
                                          color: const Color(0xFFFF8B3D),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Checkbox Indicator
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone ? AppColors.success : Colors.transparent,
                                    border: Border.all(
                                      color: isDone ? AppColors.success : AppColors.cardBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 6. Action Buttons Row: Check-in All + Share
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          allDone ? Icons.check_circle_rounded : Icons.checklist_rounded,
                          size: 18,
                        ),
                        label: Text(allDone ? 'All Done for Today 🎉' : 'Check-In All Today'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allDone
                              ? AppColors.cardSurfaceHover
                              : AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: allDone
                            ? null
                            : () async {
                                HapticFeedback.heavyImpact();
                                final count = await ref
                                    .read(habitsProvider.notifier)
                                    .checkInAllToday();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Completed $count habit(s) today! Streak preserved 🔥',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Share Dev Card',
                      icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.textSecondary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.cardSurfaceLight,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ShareDevCardDialog.show(context);
                      },
                    ),
                    if (onAddHabit != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Add Habit',
                        icon: const Icon(Icons.add_rounded, size: 22, color: AppColors.accentCyan),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cardSurfaceLight,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onAddHabit!();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatPill({
    required String icon,
    required String title,
    required String value,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceLight.withAlpha(140),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoMicro.copyWith(
                color: AppColors.textMuted,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoBadge.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationStatusBar(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(automationSettingsProvider).value;
    final isAutoCheckin = settings?.isAutoCheckinEnabled ?? true;
    final isAutoFreeze = settings?.isAutoFreezeEnabled ?? true;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        AutomationSettingsDialog.show(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withAlpha(120),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF22C55E).withAlpha(80),
            width: 0.9,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Text('⚡', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Automations & Shields',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LIVE',
                          style: AppTypography.monoMicro.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF22C55E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isAutoCheckin ? "⚡ Auto-Checkin" : "Checkin off"} • ${isAutoFreeze ? "🛡️ Auto-Rescue" : "Shield off"}',
                    style: AppTypography.monoMicro.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}



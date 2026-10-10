import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bento_card.dart';
import 'contribution_heatmap.dart';

enum HabitCardDisplayMode { single, weekly, yearly }

/// Bento habit card supporting Single, Weekly, and Yearly visualization modes
/// matching the exact design from the reference screenshots.
class BentoHabitItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color categoryColor;
  final int streak;
  final int totalDays;
  final bool isCompletedToday;
  final ValueChanged<bool?> onToggle;
  final void Function(DateTime date)? onToggleDate;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Map<DateTime, int>? activityData;
  final String actionLabel;
  final HabitCardDisplayMode displayMode;

  const BentoHabitItem({
    super.key,
    required this.title,
    required this.icon,
    this.categoryColor = AppColors.accentPrimary,
    required this.streak,
    this.totalDays = 30,
    required this.isCompletedToday,
    required this.onToggle,
    this.onToggleDate,
    this.onTap,
    this.onDelete,
    this.activityData,
    this.actionLabel = '✓',
    this.displayMode = HabitCardDisplayMode.yearly,
  });

  List<Color> _buildCustomColorScale(Color baseColor) {
    return [
      const Color(0xFF21262D),
      baseColor.withAlpha(80),
      baseColor.withAlpha(140),
      baseColor.withAlpha(200),
      baseColor,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMap = activityData ?? _generateFallbackActivity();

    return BentoCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Title + Streak + Days + Action Button
          Row(
            children: [
              // Habit Icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: categoryColor),
              ),

              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Streak indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '$streak',
                    style: AppTypography.monoBadge.copyWith(
                      color: streak > 0 ? AppColors.fireStreak : AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Total Days indicator
              Text(
                '${totalDays}d',
                style: AppTypography.monoMicro.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),

              const SizedBox(width: 10),

              // Completion Action Button Pill
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onToggle(!isCompletedToday);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompletedToday
                        ? categoryColor
                        : AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCompletedToday
                          ? categoryColor
                          : AppColors.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  child: isCompletedToday
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          actionLabel,
                          style: AppTypography.monoMicro.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 16),
                  color: AppColors.textMuted,
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDelete?.call();
                  },
                  tooltip: 'Options',
                ),
              ],
            ],
          ),

          // Display Mode Specific Body
          if (displayMode == HabitCardDisplayMode.yearly) ...[
            const SizedBox(height: 14),
            ContributionHeatmap(
              datasets: effectiveMap,
              cellSize: 10.5,
              cellSpacing: 2.5,
              cellRadius: 2.5,
              colorScale: _buildCustomColorScale(categoryColor),
              showMonthLabels: true,
              showDayLabels: false,
            ),
          ] else if (displayMode == HabitCardDisplayMode.weekly) ...[
            const SizedBox(height: 14),
            _buildWeeklyBubbleRow(effectiveMap),
          ] else ...[
            // Single view mode: clean stats pill
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompletedToday
                      ? '✓ Completed for today'
                      : 'Pending completion today',
                  style: AppTypography.bodySmall.copyWith(
                    color: isCompletedToday
                        ? AppColors.success
                        : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Tap card for history →',
                  style: AppTypography.monoMicro.copyWith(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyBubbleRow(Map<DateTime, int> dataset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final date = weekDays[i];
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isFuture = date.isAfter(today);
        final isDone = (dataset[date] ?? 0) > 0;

        return GestureDetector(
          onTap: isFuture
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onToggleDate?.call(date);
                },
          child: Column(
            children: [
              Text(
                dayNames[i],
                style: AppTypography.monoMicro.copyWith(
                  fontSize: 10,
                  color: isToday ? AppColors.accentPrimary : AppColors.textMuted,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone
                      ? categoryColor
                      : (isFuture
                          ? AppColors.cardSurfaceLight.withAlpha(100)
                          : AppColors.cardSurfaceLight),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isToday
                        ? (isDone ? categoryColor : AppColors.accentPrimary)
                        : (isDone ? categoryColor : AppColors.cardBorder),
                    width: isToday ? 1.5 : 1.0,
                  ),
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                            color: categoryColor.withAlpha(60),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${date.day}',
                        style: AppTypography.monoMicro.copyWith(
                          color: isFuture
                              ? AppColors.textMuted.withAlpha(100)
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Map<DateTime, int> _generateFallbackActivity() {
    final now = DateTime.now();
    final Map<DateTime, int> map = {};
    for (int i = 0; i < 90; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      if (i < streak) {
        map[date] = 3;
      } else if (i % 3 != 0) {
        map[date] = (i % 4) + 1;
      }
    }
    return map;
  }
}

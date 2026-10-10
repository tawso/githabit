import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../freeze/presentation/streak_freeze_dialog.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import 'day_streak_sheet.dart';

/// Pixel-perfect animated reproduction of the DayStreak iOS Widget from the reference image:
/// - Breathing organic flame glow with smooth pulsing animation
/// - Living pulsating neon ring for the in-progress "Today" circle
/// - Curved spring progress bar animation for daily dev goal completion
/// - Tactile spring bounce on taps with haptic feedback
/// - Fully reactive to live habit completions and streak freezes
class DayStreakCard extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const DayStreakCard({
    super.key,
    this.onTap,
  });

  /// Static helper to display the Day Streak as a bottom sheet modal (like QuickToolboxSheet)
  static Future<void> show(BuildContext context, {VoidCallback? onAddHabit}) {
    return DayStreakSheet.show(context, onAddHabit: onAddHabit);
  }

  @override
  ConsumerState<DayStreakCard> createState() => _DayStreakCardState();
}

class _DayStreakCardState extends ConsumerState<DayStreakCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakMetrics = ref.watch(streakProvider);
    final effectiveStreak = streakMetrics.currentStreak;
    final completedHabits = streakMetrics.completedToday;
    final totalHabits = streakMetrics.totalHabits;
    final progressPercent = streakMetrics.progressPercentInt;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13161B), // Deep graphite dark surface matching reference
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF262C36),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Row: Glowing Living Flame + "STREAK X DAYS" + Right Action Icon
            Row(
              children: [
                // Animated Living Flame Badge with breathing radial glow
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    StreakFreezeDialog.show(context);
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final pulse = _pulseAnimation.value;
                      return Transform.scale(
                        scale: 1.0 + (0.04 * pulse),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: const [
                                Color(0xFFFF3D00), // Intense flame red-orange
                                Color(0xFFFF6D00), // Bright neon amber
                                Color(0xFFDD2C00), // Darker edge
                              ],
                              center: Alignment(-0.2 - (0.1 * pulse), -0.2),
                              radius: 0.9 + (0.1 * pulse),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5722)
                                    .withAlpha((130 + (80 * pulse)).toInt()),
                                blurRadius: 18 + (12 * pulse),
                                spreadRadius: 1.5 + (2.0 * pulse),
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: const Center(
                      child: Text(
                        '🔥',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Streak Title and Days Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STREAK',
                        style: AppTypography.monoMicro.copyWith(
                          color: const Color(0xFF8B949E),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$effectiveStreak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DAYS',
                            style: AppTypography.monoMicro.copyWith(
                              color: const Color(0xFFC9D1D9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right Top Icon (Footprints / Terminal icon in photo)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.terminal_rounded,
                    color: Color(0xFFC9D1D9),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 2. Middle Row: 7-Day Circular Status (Mon - Sun)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: streakMetrics.weekDays.map((dayStatus) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDayCircle(
                      dayStatus: dayStatus,
                      onTap: dayStatus.isToday
                          ? () async {
                              HapticFeedback.mediumImpact();
                              await ref.read(habitsProvider.notifier).checkInAllToday();
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayStatus.label,
                      style: AppTypography.monoMicro.copyWith(
                        color: dayStatus.isToday
                            ? Colors.white
                            : const Color(0xFF6E7681),
                        fontSize: 10,
                        fontWeight: dayStatus.isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 3. Bottom Row: Goal Title & Progress Numbers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY DEV GOAL',
                      style: AppTypography.monoMicro.copyWith(
                        color: const Color(0xFF8B949E),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$completedHabits',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          ' /$totalHabits HABITS',
                          style: AppTypography.monoMicro.copyWith(
                            color: const Color(0xFF6E7681),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '$progressPercent%',
                  style: AppTypography.monoValue.copyWith(
                    color: const Color(0xFF8B949E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4. Smooth Spring Animated Neon Green Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Inactive dark track
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: const Color(0xFF21262D),
                  ),
                  // Smooth Animated Neon Green Active Fill
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: (progressPercent / 100).clamp(0.04, 1.0),
                    ),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF22C55E), // Vivid green
                                Color(0xFF4ADE80), // Neon lime highlight
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withAlpha(190),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCircle({
    required WeekDayStatus dayStatus,
    VoidCallback? onTap,
  }) {
    const double size = 34.0;

    if (dayStatus.isFrozen) {
      // Frozen day: Frost shield sphere
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7DD3FC), // Sky highlight
                Color(0xFF0284C7), // Frost blue
                Color(0xFF0369A1), // Deep navy shadow
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withAlpha(140),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.ac_unit_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    } else if (dayStatus.isCompleted) {
      // 1. Completed: 3D Glossy Neon Green Sphere with checkmark
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4ADE80), // Specular light lime
                Color(0xFF22C55E), // Rich neon green
                Color(0xFF16A34A), // Deep green shadow
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withAlpha(140),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFF064E3B), // Deep emerald checkmark
              size: 20,
              weight: 800,
            ),
          ),
        ),
      );
    } else if (dayStatus.isToday) {
      // 2. Today in progress: Living Pulsing Neon Green Ring Outline with dark center
      return GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            final pulse = _pulseAnimation.value;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF13161B),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF16A34A),
                    const Color(0xFF4ADE80),
                    pulse,
                  )!,
                  width: 2.2 + (0.5 * pulse),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E)
                        .withAlpha((70 + (60 * pulse)).toInt()),
                    blurRadius: 6 + (8 * pulse),
                    spreadRadius: 0.5 * pulse,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E)
                        .withAlpha((100 + (100 * pulse)).toInt()),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // 3. Inactive / Future Day: Smooth dark slate circle
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF21262D), // Slate dark matching reference
        ),
      );
    }
  }
}

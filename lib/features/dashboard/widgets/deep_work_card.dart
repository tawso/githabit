import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../pomodoro/presentation/pomodoro_provider.dart';

class DeepWorkCard extends ConsumerStatefulWidget {
  const DeepWorkCard({super.key});

  @override
  ConsumerState<DeepWorkCard> createState() => _DeepWorkCardState();
}

class _DeepWorkCardState extends ConsumerState<DeepWorkCard> {
  static const int _defaultSeconds = 25 * 60; // 25 minutes
  int _targetSeconds = _defaultSeconds;
  int _remainingSeconds = _defaultSeconds;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          final minutes = _targetSeconds ~/ 60;
          ref.read(pomodoroProvider.notifier).recordSession(minutes);
          setState(() {
            _isRunning = false;
            _remainingSeconds = _targetSeconds;
          });
          _notifyCompletedSession();
        }
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _targetSeconds;
    });
  }

  void _setDuration(int minutes) {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _targetSeconds = minutes * 60;
      _remainingSeconds = _targetSeconds;
    });
  }

  void _notifyCompletedSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          '🔥 Deep Work Session Completed! Great progress.',
          style: AppTypography.labelSmall.copyWith(color: Colors.white),
        ),
      ),
    );
    // Refresh habits in case a habit is linked
    ref.read(habitsProvider.notifier).loadHabits();
  }

  String _formatTime(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroAsync = ref.watch(pomodoroProvider);
    final completedSessions = pomodoroAsync.value?.completedToday ?? 0;
    final totalFocusMins = pomodoroAsync.value?.focusMinutesToday ?? 0;

    final progress = _targetSeconds > 0
        ? (1.0 - (_remainingSeconds / _targetSeconds)).clamp(0.0, 1.0)
        : 0.0;

    final totalHours = totalFocusMins ~/ 60;
    final totalMins = totalFocusMins % 60;

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.fireStreak.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.fireStreak,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deep Work Pomodoro',
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDurationChip(25, '25m'),
                  const SizedBox(width: 6),
                  _buildDurationChip(50, '50m'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Timer Centerpiece
          Row(
            children: [
              // Circular progress timer ring
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.cardSurfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.fireStreak,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: AppTypography.monoMetric.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Controls & Daily Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRunning ? '⚡ Session in progress...' : 'Ready to focus',
                      style: AppTypography.bodySmall.copyWith(
                        color: _isRunning
                            ? AppColors.fireStreak
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today: $completedSessions sessions (${totalHours}h ${totalMins}m)',
                      style: AppTypography.monoMicro,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleTimer,
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 18,
                          ),
                          label: Text(_isRunning ? 'Pause' : 'Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRunning
                                ? AppColors.cardSurfaceHover
                                : AppColors.fireStreak,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          color: AppColors.textMuted,
                          splashRadius: 18,
                          tooltip: 'Reset timer',
                          onPressed: _resetTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _targetSeconds == minutes * 60;
    return GestureDetector(
      onTap: () => _setDuration(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.fireStreak.withAlpha(40)
              : AppColors.cardSurfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.fireStreak : AppColors.cardBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoMicro.copyWith(
            color: isSelected ? AppColors.fireStreak : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


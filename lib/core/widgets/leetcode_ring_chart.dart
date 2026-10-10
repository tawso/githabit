import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular multi-arc gauge visualizing LeetCode solved problems
/// matching the exact layout in the official LeetCode profile reference.
class LeetCodeRingChart extends StatelessWidget {
  final int easySolved;
  final int easyTotal;
  final int mediumSolved;
  final int mediumTotal;
  final int hardSolved;
  final int hardTotal;
  final int attempting;
  final double size;
  final double strokeWidth;

  const LeetCodeRingChart({
    super.key,
    required this.easySolved,
    this.easyTotal = 935,
    required this.mediumSolved,
    this.mediumTotal = 2033,
    required this.hardSolved,
    this.hardTotal = 920,
    this.attempting = 1,
    this.size = 145,
    this.strokeWidth = 9.0,
  });

  int get totalSolved => easySolved + mediumSolved + hardSolved;
  int get totalQuestions => easyTotal + mediumTotal + hardTotal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _LeetCodeGaugePainter(
              easySolved: easySolved,
              easyTotal: easyTotal,
              mediumSolved: mediumSolved,
              mediumTotal: mediumTotal,
              hardSolved: hardSolved,
              hardTotal: hardTotal,
              attempting: attempting,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$totalSolved',
                    style: AppTypography.monoMetric.copyWith(
                      fontSize: size * 0.17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/$totalQuestions',
                    style: AppTypography.monoMicro.copyWith(
                      fontSize: size * 0.08,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 12, color: AppColors.success),
                  const SizedBox(width: 3),
                  Text(
                    'Solved',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: size * 0.085,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (attempting > 0 && size >= 100) ...[
                const SizedBox(height: 2),
                Text(
                  '$attempting Attempting',
                  style: AppTypography.monoMicro.copyWith(
                    fontSize: size * 0.07,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LeetCodeGaugePainter extends CustomPainter {
  final int easySolved;
  final int easyTotal;
  final int mediumSolved;
  final int mediumTotal;
  final int hardSolved;
  final int hardTotal;
  final int attempting;
  final double strokeWidth;

  _LeetCodeGaugePainter({
    required this.easySolved,
    required this.easyTotal,
    required this.mediumSolved,
    required this.mediumTotal,
    required this.hardSolved,
    required this.hardTotal,
    required this.attempting,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track circle (background arc)
    final trackPaint = Paint()
      ..color = const Color(0xFF262C36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background 300 degree arc (gap at bottom)
    const startAngle = 0.75 * math.pi; // ~135 degrees
    const totalSweep = 1.5 * math.pi; // 270 degrees

    canvas.drawArc(rect, startAngle, totalSweep, false, trackPaint);

    final totalTarget = (easyTotal + mediumTotal + hardTotal);
    if (totalTarget == 0) return;

    final easyFraction = (easySolved / totalTarget).clamp(0.0, 1.0);
    final mediumFraction = (mediumSolved / totalTarget).clamp(0.0, 1.0);
    final hardFraction = (hardSolved / totalTarget).clamp(0.0, 1.0);

    double currentAngle = startAngle;

    void drawSegment(double fraction, Color color) {
      if (fraction <= 0) return;
      final sweep = fraction * totalSweep * 2.5; // Scaled sweep
      if (sweep <= 0) return;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, currentAngle, sweep.clamp(0.0, totalSweep), false, paint);
      currentAngle += sweep;
    }

    // Draw Easy (Teal)
    drawSegment(easyFraction, AppColors.leetCodeEasy);
    // Draw Medium (Yellow)
    drawSegment(mediumFraction, AppColors.leetCodeMedium);
    // Draw Hard (Red)
    drawSegment(hardFraction, AppColors.leetCodeHard);

    // Attempting dot / small cyan arc
    if (attempting > 0) {
      final attemptingPaint = Paint()
        ..color = AppColors.accentCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, currentAngle + 0.08, 0.08, false, attemptingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeetCodeGaugePainter oldDelegate) {
    return oldDelegate.easySolved != easySolved ||
        oldDelegate.mediumSolved != mediumSolved ||
        oldDelegate.hardSolved != hardSolved ||
        oldDelegate.attempting != attempting;
  }
}

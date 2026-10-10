import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/year_progress_grid.dart';

/// Compact 2026 Progress Bento Card matching the left card from the reference photo:
/// - Title: "2026 Progress"
/// - Big percentage: "76%"
/// - 7-row compact matrix of green dots filling up the year
class YearProgressMiniCard extends StatelessWidget {
  final double? percentage;

  const YearProgressMiniCard({super.key, this.percentage});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    final totalDaysInYear = isLeap ? 366 : 365;
    final dayOfYear = now.difference(DateTime(year, 1, 1)).inDays + 1;
    final effectivePercentage =
        percentage ?? (dayOfYear / totalDaysInYear).clamp(0.0, 1.0);
    final pctInt = (effectivePercentage * 100).round();

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$year Progress',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pctInt%',
                style: AppTypography.monoMetric.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 7-row mini dot matrix matching photo
          SizedBox(
            height: 70,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniMatrixPainter(
                fillRatio: effectivePercentage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMatrixPainter extends CustomPainter {
  final double fillRatio;

  _MiniMatrixPainter({required this.fillRatio});

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 7;
    const cols = 15;
    const spacing = 3.0;

    final cellWidth = (size.width - ((cols - 1) * spacing)) / cols;
    final cellHeight = (size.height - ((rows - 1) * spacing)) / rows;
    final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    final filledPaint = Paint()
      ..color = const Color(0xFF26A641)
      ..style = PaintingStyle.fill;

    final todayPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final todayGlowPaint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final emptyPaint = Paint()
      ..color = const Color(0xFF21262D)
      ..style = PaintingStyle.fill;

    final totalDots = rows * cols;
    final filledDots = (totalDots * fillRatio).round();

    int dotIndex = 0;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final x = c * (cellSize + spacing);
        final y = r * (cellSize + spacing);
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.0));

        if (dotIndex == filledDots - 1 && filledDots > 0) {
          canvas.drawRRect(rrect.inflate(1.0), todayGlowPaint);
          canvas.drawRRect(rrect, todayPaint);
        } else if (dotIndex < filledDots) {
          canvas.drawRRect(rrect, filledPaint);
        } else {
          canvas.drawRRect(rrect, emptyPaint);
        }
        dotIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMatrixPainter oldDelegate) =>
      oldDelegate.fillRatio != fillRatio;
}

/// Full Year Progress Card
class YearProgressCard extends StatelessWidget {
  const YearProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 16,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Year Progress', style: AppTypography.titleSmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder, width: 0.5),
                ),
                child: Text('365 Days', style: AppTypography.monoMicro),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const YearProgressGrid(isCompact: true),
        ],
      ),
    );
  }
}

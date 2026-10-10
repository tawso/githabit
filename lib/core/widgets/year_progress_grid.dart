import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Full-year (365-day) vertical matrix visualizing elapsed vs remaining days
/// matching the exact design from the reference screenshot.
class YearProgressGrid extends StatelessWidget {
  final DateTime? currentDate;
  final double cellSpacing;
  final double cellRadius;
  final bool isCompact;

  const YearProgressGrid({
    super.key,
    this.currentDate,
    this.cellSpacing = 3.5,
    this.cellRadius = 2.5,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = currentDate ?? DateTime.now();
    final year = now.year;
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    final totalDaysInYear = isLeap ? 366 : 365;

    final firstDayOfYear = DateTime(year, 1, 1);
    final dayOfYear = now.difference(firstDayOfYear).inDays + 1;
    final daysElapsed = dayOfYear.clamp(1, totalDaysInYear);
    final daysRemaining = totalDaysInYear - daysElapsed;
    final percentage = ((daysElapsed / totalDaysInYear) * 100).round();

    const columns = 14;
    final rows = (totalDaysInYear / columns).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Year Title Header (e.g. "2026")
        Text(
          '$year',
          style: AppTypography.titleLarge.copyWith(
            fontSize: isCompact ? 28 : 36,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: AppColors.textPrimary.withAlpha(235),
          ),
        ),

        SizedBox(height: isCompact ? 12 : 18),

        // 14-column x 27-row Matrix Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final maxCellSize = isCompact ? 10.5 : 15.0;
            final computedCellSize =
                (availableWidth - ((columns - 1) * cellSpacing)) / columns;
            final cellSize = math.min(computedCellSize, maxCellSize).clamp(4.0, maxCellSize);
            final effectiveGridWidth = columns * cellSize + (columns - 1) * cellSpacing;
            final gridHeight = rows * cellSize + (rows - 1) * cellSpacing;

            return Center(
              child: SizedBox(
                width: effectiveGridWidth,
                height: gridHeight,
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(effectiveGridWidth, gridHeight),
                    painter: _YearVerticalMatrixPainter(
                      columns: columns,
                      rows: rows,
                      totalDays: totalDaysInYear,
                      daysElapsed: daysElapsed,
                      cellSize: cellSize,
                      cellSpacing: cellSpacing,
                      cellRadius: cellRadius,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: isCompact ? 12 : 18),

        // Bottom status: "299d left · 18%"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${daysRemaining}d left',
              style: AppTypography.monoValue.copyWith(
                color: AppColors.githubLevel4,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 13 : 15,
              ),
            ),
            Text(
              ' · ',
              style: AppTypography.monoValue.copyWith(
                color: AppColors.textMuted,
                fontSize: isCompact ? 13 : 15,
              ),
            ),
            Text(
              '$percentage%',
              style: AppTypography.monoValue.copyWith(
                color: AppColors.textSecondary,
                fontSize: isCompact ? 13 : 15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YearVerticalMatrixPainter extends CustomPainter {
  final int columns;
  final int rows;
  final int totalDays;
  final int daysElapsed;
  final double cellSize;
  final double cellSpacing;
  final double cellRadius;

  _YearVerticalMatrixPainter({
    required this.columns,
    required this.rows,
    required this.totalDays,
    required this.daysElapsed,
    required this.cellSize,
    required this.cellSpacing,
    required this.cellRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final elapsedPaint = Paint()
      ..color = const Color(0xFF26A641)
      ..style = PaintingStyle.fill;

    final todayPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final todayGlowPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final remainingPaint = Paint()
      ..color = const Color(0xFF21262D)
      ..style = PaintingStyle.fill;

    int day = 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        if (day > totalDays) break;

        final x = c * (cellSize + cellSpacing);
        final y = r * (cellSize + cellSpacing);
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cellRadius));

        if (day < daysElapsed) {
          canvas.drawRRect(rrect, elapsedPaint);
        } else if (day == daysElapsed) {
          // Glow effect for today
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.inflate(1.2),
              Radius.circular(cellRadius + 1),
            ),
            todayGlowPaint,
          );
          // Bright white current day dot
          canvas.drawRRect(rrect, todayPaint);
        } else {
          canvas.drawRRect(rrect, remainingPaint);
        }

        day++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _YearVerticalMatrixPainter oldDelegate) {
    return oldDelegate.daysElapsed != daysElapsed ||
        oldDelegate.totalDays != totalDays ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.columns != columns;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Single daily contribution entry
class HeatmapDayData {
  final DateTime date;
  final int count;
  final int intensity; // 0 to 4

  const HeatmapDayData({
    required this.date,
    required this.count,
    required this.intensity,
  });

  /// Normalize date to YYYY-MM-DD
  DateTime get normalizedDate => DateTime(date.year, date.month, date.day);
}

/// High-performance 7-row matrix contribution heatmap rendered
/// strictly with [CustomPainter]. Supports horizontal scrolling,
/// touch inspection/tooltips, streaks, and custom color scales.
class ContributionHeatmap extends StatefulWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  final DateTime endDate;
  final List<Color> colorScale;
  final double cellSize;
  final double cellSpacing;
  final double cellRadius;
  final void Function(DateTime date, int count)? onDayTap;
  final bool showMonthLabels;
  final bool showDayLabels;

  ContributionHeatmap({
    super.key,
    required this.datasets,
    DateTime? startDate,
    DateTime? endDate,
    this.colorScale = AppColors.githubScale,
    this.cellSize = 12.0,
    this.cellSpacing = 3.0,
    this.cellRadius = 2.5,
    this.onDayTap,
    this.showMonthLabels = true,
    this.showDayLabels = true,
  })  : endDate = endDate ?? _normalizeDate(DateTime.now()),
        startDate = startDate ??
            _normalizeDate(DateTime.now()).subtract(const Duration(days: 140));

  static DateTime _normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  @override
  State<ContributionHeatmap> createState() => _ContributionHeatmapState();
}

class _ContributionHeatmapState extends State<ContributionHeatmap> {
  DateTime? _selectedDate;
  int? _selectedCount;

  late List<List<HeatmapDayData?>> _weeks; // 7 rows per week
  late List<String> _monthLabels;
  late List<int> _monthPositions;

  @override
  void initState() {
    super.initState();
    _computeMatrix();
  }

  @override
  void didUpdateWidget(covariant ContributionHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datasets != widget.datasets ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _computeMatrix();
    }
  }

  void _computeMatrix() {
    final start = widget.startDate;
    final end = widget.endDate;

    // Align start date to Monday (weekday = 1, so row 0 = Mon, 6 = Sun)
    final daysToSubtract = (start.weekday - 1);
    final alignedStart = start.subtract(Duration(days: daysToSubtract));

    final totalDays = end.difference(alignedStart).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    final List<List<HeatmapDayData?>> weeks = [];
    final List<String> monthLabels = [];
    final List<int> monthPositions = [];
    int lastMonth = -1;

    for (int w = 0; w < totalWeeks; w++) {
      final List<HeatmapDayData?> week = [];
      for (int d = 0; d < 7; d++) {
        final current = alignedStart.add(Duration(days: w * 7 + d));
        if (current.isBefore(start) || current.isAfter(end)) {
          week.add(null);
        } else {
          final norm = ContributionHeatmap._normalizeDate(current);
          final count = widget.datasets[norm] ?? 0;
          final intensity = _computeIntensity(count);
          week.add(HeatmapDayData(
            date: norm,
            count: count,
            intensity: intensity,
          ));

          if (current.month != lastMonth && d == 0) {
            lastMonth = current.month;
            monthLabels.add(DateFormat.MMM().format(current));
            monthPositions.add(w);
          }
        }
      }
      weeks.add(week);
    }

    _weeks = weeks;
    _monthLabels = monthLabels;
    _monthPositions = monthPositions;
  }

  int _computeIntensity(int count) {
    if (count <= 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 9) return 3;
    return 4;
  }

  void _handleTap(Offset localPosition) {
    final leftPadding = widget.showDayLabels ? 28.0 : 0.0;
    final topPadding = widget.showMonthLabels ? 20.0 : 0.0;

    final adjustedX = localPosition.dx - leftPadding;
    final adjustedY = localPosition.dy - topPadding;

    if (adjustedX < 0 || adjustedY < 0) {
      setState(() {
        _selectedDate = null;
      });
      return;
    }

    final columnWidth = widget.cellSize + widget.cellSpacing;
    final rowHeight = widget.cellSize + widget.cellSpacing;

    final weekIdx = (adjustedX / columnWidth).floor();
    final dayIdx = (adjustedY / rowHeight).floor();

    if (weekIdx >= 0 &&
        weekIdx < _weeks.length &&
        dayIdx >= 0 &&
        dayIdx < 7) {
      final item = _weeks[weekIdx][dayIdx];
      if (item != null) {
        setState(() {
          _selectedDate = item.date;
          _selectedCount = item.count;
        });
        widget.onDayTap?.call(item.date, item.count);
        return;
      }
    }

    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftPadding = widget.showDayLabels ? 28.0 : 0.0;
    final topPadding = widget.showMonthLabels ? 20.0 : 0.0;
    final columnWidth = widget.cellSize + widget.cellSpacing;
    final rowHeight = widget.cellSize + widget.cellSpacing;

    final totalWidth = leftPadding + (_weeks.length * columnWidth);
    final totalHeight = topPadding + (7 * rowHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heatmap Matrix Canvas
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition),
            behavior: HitTestBehavior.opaque,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _HeatmapPainter(
                  weeks: _weeks,
                  colorScale: widget.colorScale,
                  cellSize: widget.cellSize,
                  cellSpacing: widget.cellSpacing,
                  cellRadius: widget.cellRadius,
                  showDayLabels: widget.showDayLabels,
                  showMonthLabels: widget.showMonthLabels,
                  monthLabels: _monthLabels,
                  monthPositions: _monthPositions,
                  selectedDate: _selectedDate,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Bottom Info Bar: Tooltip/Selection & Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _selectedDate != null
                  ? Text(
                      '${DateFormat('MMM d, yyyy').format(_selectedDate!)}: $_selectedCount ${_selectedCount == 1 ? "contribution" : "contributions"}',
                      style: AppTypography.monoBadge.copyWith(
                        color: AppColors.accentCyan,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      'Tap a day for details',
                      style: AppTypography.monoMicro,
                    ),
            ),
            _buildLegend(),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Less ', style: AppTypography.monoMicro),
        for (final color in widget.colorScale) ...[
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppColors.cardBorder.withAlpha(128),
                width: 0.5,
              ),
            ),
          ),
        ],
        Text(' More', style: AppTypography.monoMicro),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<List<HeatmapDayData?>> weeks;
  final List<Color> colorScale;
  final double cellSize;
  final double cellSpacing;
  final double cellRadius;
  final bool showDayLabels;
  final bool showMonthLabels;
  final List<String> monthLabels;
  final List<int> monthPositions;
  final DateTime? selectedDate;

  _HeatmapPainter({
    required this.weeks,
    required this.colorScale,
    required this.cellSize,
    required this.cellSpacing,
    required this.cellRadius,
    required this.showDayLabels,
    required this.showMonthLabels,
    required this.monthLabels,
    required this.monthPositions,
    required this.selectedDate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = showDayLabels ? 28.0 : 0.0;
    final topPadding = showMonthLabels ? 20.0 : 0.0;

    final cellPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Paint Month Labels
    if (showMonthLabels) {
      for (int i = 0; i < monthLabels.length; i++) {
        final weekIdx = monthPositions[i];
        final x = leftPadding + weekIdx * (cellSize + cellSpacing);
        textPainter.text = TextSpan(
          text: monthLabels[i],
          style: AppTypography.monoMicro.copyWith(fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, 2));
      }
    }

    // 2. Paint Day of Week Labels (Mon, Wed, Fri)
    if (showDayLabels) {
      final days = ['Mon', '', 'Wed', '', 'Fri', '', ''];
      for (int r = 0; r < 7; r++) {
        if (days[r].isNotEmpty) {
          textPainter.text = TextSpan(
            text: days[r],
            style: AppTypography.monoMicro.copyWith(fontSize: 8.5),
          );
          textPainter.layout();
          final y = topPadding + r * (cellSize + cellSpacing) + 1.0;
          textPainter.paint(canvas, Offset(2, y));
        }
      }
    }

    // 3. Paint Grid Cells
    for (int w = 0; w < weeks.length; w++) {
      final week = weeks[w];
      final x = leftPadding + w * (cellSize + cellSpacing);

      for (int d = 0; d < 7; d++) {
        final item = week[d];
        final y = topPadding + d * (cellSize + cellSpacing);
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cellRadius));

        if (item == null) {
          cellPaint.color = Colors.transparent;
          canvas.drawRRect(rrect, cellPaint);
        } else {
          final colorIdx = item.intensity.clamp(0, colorScale.length - 1);
          cellPaint.color = colorScale[colorIdx];
          canvas.drawRRect(rrect, cellPaint);

          borderPaint.color = AppColors.cardBorder.withAlpha(50);
          canvas.drawRRect(rrect, borderPaint);

          if (selectedDate != null &&
              selectedDate!.year == item.date.year &&
              selectedDate!.month == item.date.month &&
              selectedDate!.day == item.date.day) {
            final highlightPaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = AppColors.accentPrimary;
            canvas.drawRRect(rrect, highlightPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.weeks != weeks ||
        oldDelegate.selectedDate != selectedDate ||
        oldDelegate.colorScale != colorScale;
  }
}


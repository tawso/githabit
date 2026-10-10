import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

enum LogoVariant {
  badge,      // In rounded squircle with dark background & perimeter glow
  glyphOnly,  // Just the vector glyph without container
  image,      // High-res rendered app icon asset with vector fallback
}

/// A crisp, resolution-independent vector & asset logo for GitHabit:
/// Combines a Git commit-branch graph with an energetic streak flame pulse.
class GitHabitLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool animated;
  final LogoVariant variant;

  const GitHabitLogo({
    super.key,
    this.size = 36.0,
    this.showText = false,
    this.animated = false,
    this.variant = LogoVariant.badge,
  });

  @override
  Widget build(BuildContext context) {
    final Widget logoWidget;
    switch (variant) {
      case LogoVariant.glyphOnly:
        logoWidget = _buildGlyph(size);
        break;
      case LogoVariant.image:
        logoWidget = _buildImageLogo();
        break;
      case LogoVariant.badge:
        logoWidget = _buildBadgeLogo();
        break;
    }

    if (!showText) {
      return logoWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        SizedBox(width: size * 0.32),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Git',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.62,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF22C55E), // Emerald neon
                      Color(0xFF38BDF8), // Electric cyan
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Habit',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: size * 0.62,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: const Color(0xFF263244),
          width: math.max(1.0, size * 0.035),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withAlpha(45),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.02,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.68,
          height: size * 0.68,
          child: CustomPaint(
            painter: _GitHabitLogoPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildImageLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withAlpha(45),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.02,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/logo/app_icon.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildBadgeLogo(),
        ),
      ),
    );
  }

  Widget _buildGlyph(double glyphSize) {
    return SizedBox(
      width: glyphSize,
      height: glyphSize,
      child: CustomPaint(
        painter: _GitHabitLogoPainter(),
      ),
    );
  }
}

/// CustomPainter rendering the minimalist Git branch + streak flame symbol.
class _GitHabitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Coordinate space: (0,0) top-left to (w,h) bottom-right
    // Geometry definition:
    // 1. Base trunk commit node (bottom left)
    // 2. Main trunk line ascending
    // 3. Right branch line branching off into second commit node
    // 4. Crown flame/loop crest ascending upwards with fiery energy

    final trunkX = w * 0.32;
    final branchX = w * 0.72;
    final bottomY = h * 0.76;
    final midY = h * 0.48;
    final topY = h * 0.20;

    final strokeWidth = math.max(2.2, w * 0.12);

    // Gradient for the branches
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gradientShader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF38BDF8), // Electric cyan at root
        Color(0xFF22C55E), // Emerald green in stem
        Color(0xFFFF6D00), // Fire amber at flame tip
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    linePaint.shader = gradientShader;

    // 1. Draw trunk vertical path
    final trunkPath = Path();
    trunkPath.moveTo(trunkX, bottomY);
    trunkPath.lineTo(trunkX, midY * 0.85);

    // 2. Draw branch path from trunk to right branch
    final branchPath = Path();
    branchPath.moveTo(trunkX, bottomY * 0.78);
    branchPath.cubicTo(
      trunkX + w * 0.05,
      midY + h * 0.08,
      branchX - w * 0.12,
      midY + h * 0.04,
      branchX,
      midY,
    );
    branchPath.lineTo(branchX, midY - h * 0.06);

    // 3. Flame crest / habit momentum loop at top of main trunk
    final flamePath = Path();
    flamePath.moveTo(trunkX, midY * 0.85);
    // Outer flame loop curving right and reaching top apex
    flamePath.cubicTo(
      trunkX - w * 0.14,
      topY + h * 0.12,
      trunkX + w * 0.08,
      topY - h * 0.06,
      w * 0.52,
      topY,
    );
    // Flame teardrop curve swooping back into the right branch
    flamePath.cubicTo(
      w * 0.68,
      topY + h * 0.04,
      branchX,
      midY - h * 0.18,
      branchX,
      midY - h * 0.06,
    );

    // Draw main connective paths
    canvas.drawPath(trunkPath, linePaint);
    canvas.drawPath(branchPath, linePaint);
    canvas.drawPath(flamePath, linePaint);

    // 4. Commit Nodes (Glowing circles)
    final nodeRadius = strokeWidth * 0.95;

    // Node 1: Base Commit Node (Bottom Trunk)
    _drawCommitNode(
      canvas,
      Offset(trunkX, bottomY),
      nodeRadius,
      const Color(0xFF38BDF8), // Cyan glow
    );

    // Node 2: Branch Commit Node (Mid Right)
    _drawCommitNode(
      canvas,
      Offset(branchX, midY),
      nodeRadius,
      const Color(0xFF22C55E), // Emerald glow
    );

    // Node 3: Apex Flame Spark Node (Top Crown)
    _drawFlameSpark(
      canvas,
      Offset(w * 0.52, topY),
      nodeRadius * 0.85,
      const Color(0xFFFF5722), // Fire glow
    );
  }

  void _drawCommitNode(
    Canvas canvas,
    Offset center,
    double radius,
    Color accentColor,
  ) {
    // Outer glow
    final glowPaint = Paint()
      ..color = accentColor.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Dark solid node body
    final bodyPaint = Paint()
      ..color = const Color(0xFF0F141C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Glowing border ring
    final ringPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.55;
    canvas.drawCircle(center, radius * 0.85, ringPaint);

    // Core bright center dot
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, centerDotPaint);
  }

  void _drawFlameSpark(
    Canvas canvas,
    Offset center,
    double radius,
    Color fireColor,
  ) {
    // Intense warm amber glow
    final glowPaint = Paint()
      ..color = fireColor.withAlpha(160)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(center, radius * 1.7, glowPaint);

    // Solid inner fire bead
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFAB00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.7, sparkPaint);

    // White hot core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

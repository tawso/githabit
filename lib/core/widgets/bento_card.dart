import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Reusable Bento grid card wrapper supporting optional onTap,
/// customizable padding, border glow, and dark mode surface styling.
class BentoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool enableGlow;
  final Color? glowColor;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppTheme.cardBorderRadius,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ??
        (_isHovered ? AppColors.cardSurfaceHover : AppColors.cardSurface);
    final effectiveBorder = widget.borderColor ??
        (_isHovered
            ? AppColors.accentPrimary.withAlpha(128)
            : AppColors.cardBorder);

    List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withAlpha(51),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    if (widget.enableGlow || _isHovered) {
      final glow = widget.glowColor ?? AppColors.accentPrimary;
      shadows.add(
        BoxShadow(
          color: glow.withAlpha(40),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      );
    }

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: effectiveBorder, width: 1.0),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      ),
    );
  }
}


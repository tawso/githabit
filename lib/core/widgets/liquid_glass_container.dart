import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Apple-style Liquid Glass (Frosted Glassmorphism) container
/// utilizing BackdropFilter, translucent surfaces, and specular highlights.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 20.0,
    this.borderRadius = 32.0,
    this.backgroundColor = const Color(0x66161B22), // 40% opacity #161B22
    this.borderColor = const Color(0x2EFFFFFF),     // 18% opacity white specular
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );

    // Apply BackdropFilter blur with ClipRRect
    content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );

    // Wrap in shadow if requested
    if (shadows != null && shadows!.isNotEmpty) {
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: content,
      );
    } else if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}


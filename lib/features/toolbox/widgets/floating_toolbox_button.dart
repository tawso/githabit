import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/liquid_glass_container.dart';

class FloatingToolboxButton extends StatefulWidget {
  final VoidCallback onPressed;

  const FloatingToolboxButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<FloatingToolboxButton> createState() => _FloatingToolboxButtonState();
}

class _FloatingToolboxButtonState extends State<FloatingToolboxButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _animController;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animController.reverse(),
        onTapUp: (_) {
          _animController.forward();
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => _animController.forward(),
        child: LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          backgroundColor: const Color(0xB3161B22), // 70% dark frosted glass
          borderColor: const Color(0x6638BDF8),     // Specular cyan glow
          borderWidth: 1.2,
          shadows: [
            BoxShadow(
              color: const Color(0xFF0284C7).withAlpha(100),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF818CF8),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Toolbox',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

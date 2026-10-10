import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'liquid_glass_container.dart';

class DockItem {
  final IconData icon;
  final String label;

  const DockItem({required this.icon, required this.label});
}

/// Floating Liquid Glass Navigation Dock matching the reference photo:
/// - Floating rounded capsule over scrolling content
/// - Real iOS frosted glass blur with specular border highlights
/// - Soft capsule pill background highlight on active tab
class FloatingLiquidGlassDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingLiquidGlassDock({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const List<DockItem> items = [
    DockItem(icon: Icons.home_rounded, label: 'Home'),
    DockItem(icon: Icons.format_list_bulleted_rounded, label: 'Habits'),
    DockItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
    DockItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
          child: LiquidGlassContainer(
            borderRadius: 36,
            blurSigma: 24,
            backgroundColor: const Color(0x73161B22), // 45% translucent dark glass
            borderColor: const Color(0x38FFFFFF),     // 22% specular highlight
            borderWidth: 1.0,
            shadows: [
              BoxShadow(
                color: Colors.black.withAlpha(170),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final isSelected = index == currentIndex;
                final item = items[index];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onItemSelected(index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with active capsule highlight (as seen on "Home" in photo)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 12 : 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withAlpha(45)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoMicro.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}


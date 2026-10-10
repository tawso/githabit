import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../badges/domain/dev_badge.dart';
import '../../badges/presentation/badges_provider.dart';

class DeveloperBadgesCard extends ConsumerWidget {
  const DeveloperBadgesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

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
                        color: AppColors.accentPurple.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        size: 16,
                        color: AppColors.accentPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dev Badges & Honors',
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder, width: 0.5),
                ),
                child: Text(
                  '$unlockedCount of ${badges.length} Unlocked',
                  style: AppTypography.monoMicro.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Badges Horizontal Carousel / Shelf
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: badges.map((badge) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showBadgeDetail(context, badge);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: badge.isUnlocked
                                ? badge.color.withAlpha(25)
                                : AppColors.cardSurfaceLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: badge.isUnlocked
                                  ? badge.color.withAlpha(160)
                                  : AppColors.cardBorder,
                              width: 1.5,
                            ),
                            boxShadow: badge.isUnlocked
                                ? [
                                    BoxShadow(
                                      color: badge.color.withAlpha(60),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: badge.isUnlocked
                              ? Text(
                                  badge.shortCode,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.monoMicro.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: badge.color,
                                  ),
                                )
                              : const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 58,
                          child: Text(
                            badge.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.monoMicro.copyWith(
                              fontSize: 9.5,
                              color: badge.isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, DevBadge badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: badge.isUnlocked ? badge.color.withAlpha(120) : AppColors.cardBorder,
          ),
        ),
        title: Row(
          children: [
            Icon(
              badge.icon,
              color: badge.isUnlocked ? badge.color : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(badge.title, style: AppTypography.titleSmall),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description, style: AppTypography.bodySmall),
            const SizedBox(height: 14),
            if (!badge.isUnlocked && badge.progress > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: AppTypography.monoMicro),
                  Text(badge.progressLabel, style: AppTypography.monoMicro.copyWith(color: badge.color)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  backgroundColor: AppColors.cardSurfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    badge.isUnlocked ? 'Status' : 'Requirement',
                    style: AppTypography.monoMicro,
                  ),
                  Text(
                    badge.dateEarned,
                    style: AppTypography.monoBadge.copyWith(
                      color: badge.isUnlocked ? badge.color : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

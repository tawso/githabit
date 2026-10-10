import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../wakatime/presentation/wakatime_provider.dart';
import '../../wakatime/presentation/wakatime_settings_dialog.dart';

class WakaTimeStatsCard extends ConsumerWidget {
  const WakaTimeStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(wakatimeStatsProvider);

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Title, Status Pill and Settings Gear
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        size: 16,
                        color: AppColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'IDE Coding Time',
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // WakaTime status pill & Settings Trigger
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.selectionClick();
                  WakaTimeSettingsDialog.show(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder, width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      statsAsync.when(
                        data: (stats) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: stats.isMock ? const Color(0xFF6E7681) : AppColors.success,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      Text(
                        'WakaTime',
                        style: AppTypography.monoMicro.copyWith(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Body with Async handling
          statsAsync.when(
            data: (stats) {
              final languages = stats.languages;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Time Today & Week
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            stats.humanReadableToday,
                            style: AppTypography.monoMetric.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('today', style: AppTypography.bodySmall),
                        ],
                      ),
                      Text(
                        stats.humanReadableWeek,
                        style: AppTypography.monoMicro.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Multi-color segmented progress bar
                  if (languages.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        height: 7,
                        child: Row(
                          children: languages.map((lang) {
                            final flex = (lang.percentage * 100).round().clamp(1, 100);
                            return Expanded(
                              flex: flex,
                              child: Container(
                                color: lang.color,
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Language Chips Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: languages.map((lang) {
                        final pct = (lang.percentage * 100).toInt();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: lang.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lang.name,
                                style: AppTypography.monoMicro.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$pct%',
                                style: AppTypography.monoMicro.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        'Tap the settings icon above to configure your WakaTime API key.',
                        style: AppTypography.monoMicro.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'WakaTime offline. Tap gear icon to configure API key.',
                style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

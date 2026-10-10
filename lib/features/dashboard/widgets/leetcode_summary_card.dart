import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/leetcode_ring_chart.dart';
import '../../leetcode/domain/leetcode_stats_model.dart';
import '../../leetcode/presentation/leetcode_provider.dart';

/// Compact LeetCode Bento Card matching the top-right card from the reference photo:
/// - Title: "LeetCode"
/// - Gauge ring with "200/3888 Solved"
/// - Stacked pills: "Easy 101", "Med. 74", "Hard 25"
class LeetCodeMiniCard extends ConsumerWidget {
  const LeetCodeMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(leetCodeStatsProvider);

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'LeetCode',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          statsAsync.when(
            data: (stats) => _buildContent(stats),
            loading: () => const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => _buildContent(
              LeetCodeStatsModel.empty(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LeetCodeStatsModel stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ring Gauge
        Expanded(
          flex: 5,
          child: LeetCodeRingChart(
            easySolved: stats.easySolved,
            easyTotal: stats.easyTotal,
            mediumSolved: stats.mediumSolved,
            mediumTotal: stats.mediumTotal,
            hardSolved: stats.hardSolved,
            hardTotal: stats.hardTotal,
            size: 82,
            strokeWidth: 6.0,
          ),
        ),

        const SizedBox(width: 8),

        // 3 Stacked Pills: Easy 101, Med. 74, Hard 25
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniPill('Easy', '${stats.easySolved}', const Color(0xFF103632), AppColors.leetCodeEasy),
              const SizedBox(height: 5),
              _buildMiniPill('Med.', '${stats.mediumSolved}', const Color(0xFF362B14), AppColors.leetCodeMedium),
              const SizedBox(height: 5),
              _buildMiniPill('Hard', '${stats.hardSolved}', const Color(0xFF361620), AppColors.leetCodeHard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPill(String label, String value, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.monoMicro.copyWith(
              color: textColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: AppTypography.monoMicro.copyWith(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full LeetCode Summary Card
class LeetCodeSummaryCard extends ConsumerWidget {
  const LeetCodeSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(leetCodeStatsProvider);
    final username = ref.watch(leetCodeUsernameProvider);

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.leetCodeMedium.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      size: 18,
                      color: AppColors.leetCodeMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LeetCode', style: AppTypography.titleSmall),
                      Text(username.isEmpty ? 'Not connected' : '@$username', style: AppTypography.monoMicro),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: AppColors.textMuted,
                splashRadius: 16,
                onPressed: () => _showEditUsernameDialog(context, ref, username),
                tooltip: 'Change LeetCode handle',
              ),
            ],
          ),

          const SizedBox(height: 16),

          statsAsync.when(
            data: (stats) => _buildStatsBody(stats),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Failed to load stats: $err', style: AppTypography.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBody(LeetCodeStatsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LeetCodeRingChart(
              easySolved: stats.easySolved,
              easyTotal: stats.easyTotal,
              mediumSolved: stats.mediumSolved,
              mediumTotal: stats.mediumTotal,
              hardSolved: stats.hardSolved,
              hardTotal: stats.hardTotal,
              attempting: stats.totalSolved > 0 ? 1 : 0,
              size: 130,
              strokeWidth: 8.5,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildStackedDifficultyCard(
                    title: 'Easy',
                    solved: stats.easySolved,
                    total: stats.easyTotal,
                    color: AppColors.leetCodeEasy,
                  ),
                  const SizedBox(height: 8),
                  _buildStackedDifficultyCard(
                    title: 'Med.',
                    solved: stats.mediumSolved,
                    total: stats.mediumTotal,
                    color: AppColors.leetCodeMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildStackedDifficultyCard(
                    title: 'Hard',
                    solved: stats.hardSolved,
                    total: stats.hardTotal,
                    color: AppColors.leetCodeHard,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Badges', style: AppTypography.labelMedium),
                const SizedBox(width: 8),
                Text(
                  stats.totalSolved >= 100
                      ? '3'
                      : (stats.totalSolved >= 50
                          ? '2'
                          : (stats.totalSolved >= 10 ? '1' : '0')),
                  style: AppTypography.monoBadge.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
        const SizedBox(height: 10),
        if (stats.totalSolved >= 10)
          Row(
            children: [
              if (stats.totalSolved >= 10)
                _buildBadgeHex(label: '10 SOLVED', color: AppColors.githubLevel3),
              if (stats.totalSolved >= 50) ...[
                const SizedBox(width: 12),
                _buildBadgeHex(label: '50 SOLVED', color: AppColors.success),
              ],
              if (stats.totalSolved >= 100) ...[
                const SizedBox(width: 12),
                _buildBadgeHex(label: 'CENTURY', color: AppColors.accentCyan),
              ],
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Most Recent Badge', style: AppTypography.monoMicro),
                  const SizedBox(height: 2),
                  Text(
                    stats.totalSolved >= 100
                        ? 'Century Badge'
                        : (stats.totalSolved >= 50 ? '50 Solved Badge' : 'Beginner Badge'),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No badges unlocked yet. Solve LeetCode problems to earn badges!',
              style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
            ),
          ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${stats.totalSolved} submissions in past year',
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
            Text(
              'Max streak: ${stats.currentStreak}d 🔥',
              style: AppTypography.monoBadge.copyWith(
                color: AppColors.fireStreak,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStackedDifficultyCard({
    required String title,
    required int solved,
    required int total,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$solved/$total',
            style: AppTypography.monoValue.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeHex({required String label, required Color color}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(150), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.monoMicro.copyWith(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Edit LeetCode Handle', style: AppTypography.titleSmall),
        content: TextField(
          controller: controller,
          style: AppTypography.monoValue,
          decoration: const InputDecoration(
            hintText: 'Enter LeetCode username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(leetCodeUsernameProvider.notifier)
                    .setUsername(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

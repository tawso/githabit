import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/contribution_heatmap.dart';
import '../../github/domain/github_activity_model.dart';
import '../../github/presentation/github_provider.dart';

class GitHubActivityCard extends ConsumerWidget {
  const GitHubActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(githubActivityProvider);
    final username = ref.watch(githubUsernameProvider);

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching screenshot: Octocat icon + "GitHub Contributions" + "🔥 1,248" + "[ 📅 ]"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.githubLevel3.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.commit_rounded,
                      size: 16,
                      color: AppColors.githubLevel4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GitHub Contributions',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  activityAsync.when(
                    data: (act) => Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${act.totalContributions}',
                          style: AppTypography.monoBadge.copyWith(
                            color: act.totalContributions > 0
                                ? AppColors.fireStreak
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => Text(
                      '🔥 0',
                      style: AppTypography.monoBadge.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showEditUsernameDialog(context, ref, username);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Heatmap Matrix Body (Full Width matching screenshot)
          activityAsync.when(
            data: (activity) => _buildActivityBody(activity, username),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Failed to load GitHub activity: $err',
                    style: AppTypography.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBody(GithubActivityModel activity, String username) {
    if (activity.contributionsMap.isEmpty && username.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceLight.withAlpha(60),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 0.6),
        ),
        child: Column(
          children: [
            const Icon(Icons.commit_rounded, color: AppColors.textMuted, size: 28),
            const SizedBox(height: 8),
            Text(
              'No GitHub account connected',
              style: AppTypography.titleSmall.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the calendar icon above to set your GitHub username',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContributionHeatmap(
          datasets: activity.contributionsMap,
          cellSize: 11.0,
          cellSpacing: 2.5,
          colorScale: AppColors.githubScale,
          showDayLabels: false,
          showMonthLabels: true,
        ),
      ],
    );
  }

  void _showEditUsernameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Edit GitHub Username', style: AppTypography.titleSmall),
        content: TextField(
          controller: controller,
          style: AppTypography.monoValue,
          decoration: const InputDecoration(
            hintText: 'Enter GitHub username',
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
                    .read(githubUsernameProvider.notifier)
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

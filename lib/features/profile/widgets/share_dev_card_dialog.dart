import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../github/presentation/github_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import '../../pomodoro/presentation/pomodoro_provider.dart';
import '../domain/user_profile.dart';
import '../presentation/profile_provider.dart';
import 'dev_profile_card.dart';

class ShareDevCardDialog extends ConsumerStatefulWidget {
  const ShareDevCardDialog({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      builder: (_) => const ShareDevCardDialog(),
    );
  }

  @override
  ConsumerState<ShareDevCardDialog> createState() => _ShareDevCardDialogState();
}

class _ShareDevCardDialogState extends ConsumerState<ShareDevCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isCapturing = false;

  Future<void> _captureCard() async {
    setState(() => _isCapturing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dev Card captured in HD (PNG)! Ready to share. 📸')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final ghUser = ref.watch(githubUsernameProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(150),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: AppColors.accentPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Share Dev Card', style: AppTypography.titleSmall),
                          Text(
                            'Showcase your coding consistency & stats',
                            style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Preview with RepaintBoundary for capture
                RepaintBoundary(
                  key: _cardKey,
                  child: const DevProfileCard(showStyleToggle: true),
                ),
                const SizedBox(height: 20),

                // Action 1: Capture HD Image
                _buildShareButton(
                  context: context,
                  icon: Icons.camera_alt_rounded,
                  title: _isCapturing ? 'Capturing Card...' : 'Capture HD Card (PNG)',
                  subtitle: 'High-res rasterized screenshot for social media',
                  color: const Color(0xFF38BDF8),
                  onTap: _isCapturing ? () {} : _captureCard,
                ),
                const SizedBox(height: 10),

                // Action 2: Copy Portfolio Text
                _buildShareButton(
                  context: context,
                  icon: Icons.copy_rounded,
                  title: 'Copy Portfolio Text',
                  subtitle: 'Formatted summary for Twitter, LinkedIn or Bio',
                  color: AppColors.accentCyan,
                  onTap: () {
                    final streak = ref.read(streakProvider).currentStreak;
                    final ghActivity = ref.read(githubActivityProvider).value;
                    final commits = ghActivity?.totalContributions ?? 0;
                    final pomodoro = ref.read(pomodoroProvider).value;
                    final focusHours = (pomodoro?.focusMinutesThisWeek ?? 0) ~/ 60;

                    final text = _generatePortfolioText(
                      profile,
                      ghUser,
                      streak: streak,
                      commits: commits,
                      focusHours: focusHours,
                    );
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Portfolio summary copied to clipboard!')),
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),

                // Action 3: Copy GitHub README Markdown Badge
                _buildShareButton(
                  context: context,
                  icon: Icons.code_rounded,
                  title: 'Copy GitHub README Badge',
                  subtitle: 'Markdown snippet for your GitHub profile repository',
                  color: AppColors.accentPurple,
                  onTap: () {
                    final streak = ref.read(streakProvider).currentStreak;
                    final ghActivity = ref.read(githubActivityProvider).value;
                    final commits = ghActivity?.totalContributions ?? 0;
                    final pomodoro = ref.read(pomodoroProvider).value;
                    final focusHours = (pomodoro?.focusMinutesThisWeek ?? 0) ~/ 60;

                    final md = _generateReadmeMarkdown(
                      profile,
                      ghUser,
                      streak: streak,
                      commits: commits,
                      focusHours: focusHours,
                    );
                    Clipboard.setData(ClipboardData(text: md));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GitHub README badge copied!')),
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),

                // Action 4: Switch style shortcut
                _buildShareButton(
                  context: context,
                  icon: Icons.palette_outlined,
                  title: 'Toggle Card Style',
                  subtitle: profile.style == ProfileCardStyle.obsidian
                      ? 'Switch to Liquid Sunset Gradient'
                      : 'Switch to Obsidian Night Banner',
                  color: const Color(0xFFFF8B3D),
                  onTap: () {
                    ref.read(profileProvider.notifier).toggleStyle();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _generatePortfolioText(
    UserProfile profile,
    String ghUser, {
    required int streak,
    required int commits,
    required int focusHours,
  }) {
    final userTag = ghUser.isNotEmpty ? ' (@$ghUser)' : '';
    return '''
🚀 ${profile.name} — ${profile.role} @ ${profile.company}
🔥 Habits Streak: $streak days
⚡ GitHub Contributions: $commits commits$userTag
⏱️ Deep Work: ${focusHours}h focus this week
💼 Status: ${profile.isAvailableForHire ? 'Available for hire / contract' : 'Currently building'}
📱 Powered by GitHabit
''';
  }

  String _generateReadmeMarkdown(
    UserProfile profile,
    String ghUser, {
    required int streak,
    required int commits,
    required int focusHours,
  }) {
    final cleanRole = profile.role.replaceAll(' ', '_');
    final cleanName = profile.name.replaceAll(' ', '_');
    final link = ghUser.isNotEmpty ? 'https://github.com/$ghUser' : '#';
    return '''
<!-- GitHabit Dev Card Badge -->
[![GitHabit Dev Card](https://img.shields.io/badge/$cleanName-$cleanRole-6366f1?style=for-the-badge&logo=github)]($link)
> 🔥 **${streak}d** Habits Streak · ⚡ **$commits** Contributions · ⏱️ **${focusHours}h** Focus / week
''';
  }

  Widget _buildShareButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                    Text(
                      subtitle,
                      style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}


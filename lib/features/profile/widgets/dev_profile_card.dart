import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../github/presentation/github_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import '../../dashboard/widgets/day_streak_sheet.dart';
import '../../pomodoro/presentation/pomodoro_provider.dart';
import '../domain/user_profile.dart';
import '../presentation/profile_provider.dart';
import 'share_dev_card_dialog.dart';

/// Developer Profile Card reproducing the exact design from the reference screenshot:
/// - Supports both "Obsidian Banner" and "Liquid Sunset" styles
/// - Overlapping avatar with online status dot
/// - Translucent company pill badge on the banner
/// - Name, role, and bookmark/share action button
/// - 3 developer stats pills: Rating/Streak, Commits, Focus Hours
/// - Bold white "Get In Touch" / "Share Dev Card" pill button
class DevProfileCard extends ConsumerWidget {
  final VoidCallback? onEditPressed;
  final bool showStyleToggle;

  const DevProfileCard({
    super.key,
    this.onEditPressed,
    this.showStyleToggle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final streakMetrics = ref.watch(streakProvider);
    final effectiveStreak = streakMetrics.currentStreak;

    final ghActivity = ref.watch(githubActivityProvider).value;
    final totalCommits = ghActivity?.totalContributions ?? 0;

    final pomodoro = ref.watch(pomodoroProvider).value;
    final focusHours = (pomodoro?.focusMinutesThisWeek ?? 0) ~/ 60;
    final effectiveFocus = focusHours;

    final isSunset = profile.style == ProfileCardStyle.liquidSunset;

    return Container(
      decoration: BoxDecoration(
        color: isSunset ? null : AppColors.cardSurface,
        gradient: isSunset
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8F1E29), // Rich crimson red
                  Color(0xFF5B173D), // Deep magenta
                  Color(0xFF231C5B), // Night indigo
                  Color(0xFF13284F), // Midnight blue
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              )
            : null,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSunset
              ? Colors.white.withAlpha(50)
              : AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSunset
                ? const Color(0x668F1E29)
                : Colors.black.withAlpha(90),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Artwork Banner (or silhouette for sunset)
              _buildTopBanner(context, ref, profile, isSunset),

              // 2. Profile Details & Stats Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name, Role & Bookmark Action Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                profile.role,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isSunset
                                      ? Colors.white.withAlpha(190)
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Bookmark / Share Icon Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showShareSheet(context, profile, effectiveStreak, totalCommits);
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSunset
                                  ? Colors.white.withAlpha(35)
                                  : AppColors.cardSurfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSunset
                                    ? Colors.white.withAlpha(50)
                                    : AppColors.cardBorder,
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.bookmark_outline_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3-Column Stats Row: Rating/Streak, Hours/Commits, Month/Focus
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSunset
                            ? Colors.black.withAlpha(50)
                            : AppColors.cardSurfaceLight.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSunset
                              ? Colors.white.withAlpha(30)
                              : AppColors.cardBorder.withAlpha(80),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('⚡', '$totalCommits', 'Commits', isSunset),
                          _buildDivider(isSunset),
                          _buildStatColumn(
                            '🔥',
                            '${effectiveStreak}d',
                            'Streak',
                            isSunset,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              DayStreakSheet.show(context);
                            },
                          ),
                          _buildDivider(isSunset),
                          _buildStatColumn('⏱️', '${effectiveFocus}h', 'Focus', isSunset),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Primary Action Button: Bold White "Get In Touch"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showContactSheet(context, profile, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Get In Touch',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Overlapping Avatar with Green Online Status Dot
          Positioned(
            left: 20,
            top: isSunset ? 48 : 86,
            child: _buildAvatarWithBadge(profile, isSunset),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isSunset,
  ) {
    if (isSunset) {
      // Liquid Sunset Header with Silhouette Portrait
      return SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyPill(context, ref, profile, isSunset),
            ],
          ),
        ),
      );
    }

    // Obsidian style with warm bokeh glowing abstract banner
    return Container(
      height: 114,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E4647), // Muted dark teal
            Color(0xFFD36830), // Warm vibrant ember
            Color(0xFFEAA25B), // Golden sunset
            Color(0xFF4A89A8), // Atmospheric blue
          ],
          stops: [0.0, 0.45, 0.75, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompanyPill(context, ref, profile, isSunset),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyPill(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isSunset,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStyleToggle) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(profileProvider.notifier).toggleStyle();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(40),
                  width: 0.8,
                ),
              ),
              child: Icon(
                isSunset ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(140),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(45),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFE02B20), // Adobe / Brand Red
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                profile.company,
                style: AppTypography.monoMicro.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarWithBadge(UserProfile profile, bool isSunset) {
    return Stack(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSunset ? const Color(0xFF6B1D45) : AppColors.cardSurface,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            color: const Color(0xFF2C2422),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Icon(
            Icons.person_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        if (profile.isAvailableForHire)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF39D353), // Live online green
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSunset ? const Color(0xFF6B1D45) : AppColors.cardSurface,
                  width: 2.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatColumn(
    String icon,
    String value,
    String label,
    bool isSunset, {
    VoidCallback? onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.monoMetric.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.monoMicro.copyWith(
            fontSize: 10,
            color: isSunset
                ? Colors.white.withAlpha(170)
                : AppColors.textMuted,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: content,
      ),
    );
  }

  Widget _buildDivider(bool isSunset) {
    return Container(
      width: 0.8,
      height: 24,
      color: isSunset
          ? Colors.white.withAlpha(40)
          : AppColors.cardBorder.withAlpha(90),
    );
  }

  void _showShareSheet(
    BuildContext context,
    UserProfile profile,
    int streak,
    int commits,
  ) {
    ShareDevCardDialog.show(context);
  }

  void _showContactSheet(BuildContext context, UserProfile profile, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Developer Hub', style: AppTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${profile.name} is currently ${profile.isAvailableForHire ? 'Available for new challenges' : 'Busy with projects'}.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppColors.success),
              title: const Text('Share & Export Dev Card'),
              subtitle: const Text('Copy portfolio text, GitHub README badge & stats'),
              onTap: () {
                Navigator.pop(ctx);
                ShareDevCardDialog.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accentPrimary),
              title: const Text('Edit Profile Details'),
              subtitle: const Text('Change name, role, company and style'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditProfileModal(context, profile, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined, color: AppColors.accentCyan),
              title: const Text('Switch Card Style'),
              subtitle: Text(
                profile.style == ProfileCardStyle.obsidian
                    ? 'Current: Obsidian Banner → Switch to Sunset'
                    : 'Current: Liquid Sunset → Switch to Obsidian',
              ),
              onTap: () {
                ref.read(profileProvider.notifier).toggleStyle();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  void _showEditProfileModal(
    BuildContext context,
    UserProfile profile,
    WidgetRef ref,
  ) {
    final nameCtrl = TextEditingController(text: profile.name);
    final roleCtrl = TextEditingController(text: profile.role);
    final compCtrl = TextEditingController(text: profile.company);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Edit Developer Profile', style: AppTypography.titleSmall),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              maxLength: 50,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              maxLength: 50,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Role / Title',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: compCtrl,
              maxLength: 50,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Company / Organization',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(profileProvider.notifier).updateProfile(
                        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                        role: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : null,
                        company: compCtrl.text.trim().isNotEmpty ? compCtrl.text.trim() : null,
                      );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}


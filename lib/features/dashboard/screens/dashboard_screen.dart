import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/floating_liquid_glass_dock.dart';
import '../../../core/widgets/githabit_logo.dart';
import '../../github/presentation/github_provider.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../leetcode/presentation/leetcode_provider.dart';
import '../widgets/deep_work_card.dart';
import '../widgets/developer_badges_card.dart';
import '../widgets/github_activity_card.dart';
import '../widgets/habits_section.dart';
import '../widgets/leetcode_summary_card.dart';
import '../widgets/wakatime_stats_card.dart';
import '../widgets/year_progress_card.dart';
import '../widgets/day_streak_sheet.dart';
import '../../habits/presentation/streak_provider.dart';
import '../../wakatime/presentation/wakatime_provider.dart';
import '../../wakatime/presentation/wakatime_settings_dialog.dart';
import '../../profile/widgets/dev_profile_card.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_provider.dart';
import '../../pomodoro/presentation/pomodoro_provider.dart';
import '../../freeze/domain/streak_freeze_state.dart';
import '../../freeze/presentation/freeze_provider.dart';
import '../../freeze/presentation/streak_freeze_dialog.dart';
import '../../toolbox/presentation/quick_toolbox_sheet.dart';
import '../../toolbox/widgets/floating_toolbox_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentNavIndex = 0;

  void _showProfileModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: const DevProfileCard(),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    HapticFeedback.lightImpact();
    ref.invalidate(githubActivityProvider);
    ref.invalidate(leetCodeStatsProvider);
    ref.read(habitsProvider.notifier).loadHabits();
  }

  void _showAddHabitDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    HabitCategory selectedCategory = HabitCategory.coding;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create New Habit', style: AppTypography.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                maxLength: 80,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g. Read RFCs / Rust Docs',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.cardSurfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLength: 250,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.cardSurfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Category', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HabitCategory.values.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 14, color: cat.color),
                        const SizedBox(width: 4),
                        Text(cat.label),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.cardSurfaceHover,
                    backgroundColor: AppColors.cardSurfaceLight,
                    onSelected: (val) {
                      if (val) {
                        setModalState(() => selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      ref.read(habitsProvider.notifier).addHabit(
                            title: title,
                            category: selectedCategory,
                            description: descController.text.trim().isEmpty
                                ? null
                                : descController.text.trim(),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    final streakMetrics = ref.watch(streakProvider);
    final finalStreak = streakMetrics.currentStreak;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      // Custom App Bar matching exact photo layout: Avatar + "GitHabit" + "🔥 156d"
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // User Avatar (Matching reference photo, tap to view Profile Card)
            GestureDetector(
              onTap: () => _showProfileModal(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentCyan.withAlpha(120),
                    width: 1.5,
                  ),
                  color: AppColors.cardSurfaceHover,
                ),
                clipBehavior: Clip.antiAlias,
                child: const Icon(
                  Icons.person,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const GitHabitLogo(size: 26, variant: LogoVariant.image),
            const SizedBox(width: 8),
            Text(
              'GitHabit',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Streak Freeze Shield Indicator Pill (Tap to open Freeze Dialog)
          GestureDetector(
            onTap: () => StreakFreezeDialog.show(context),
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2A4A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withAlpha(140),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❄️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${ref.watch(streakFreezeProvider).value?.availableFreezes ?? 2}',
                      style: AppTypography.monoBadge.copyWith(
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 22),
            tooltip: 'Add new habit',
            onPressed: () => _showAddHabitDialog(context),
          ),
          // Total Streak Pill Badge (Tap opens DayStreakSheet modal)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  DayStreakSheet.show(
                    context,
                    onAddHabit: () => _showAddHabitDialog(context),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1C12), // Warm dark orange background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5C331B),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withAlpha(45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '${finalStreak}d',
                        style: AppTypography.monoBadge.copyWith(
                          color: const Color(0xFFFF8B3D),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Body Stack: Content layer underneath + Floating Liquid Glass Dock layer on top
      body: Stack(
        children: [
          // Content Layer with IndexedStack preserving state and scroll position
          Positioned.fill(
            child: IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildHomeTab(),
                _buildHabitsTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),

          // Floating Liquid Glass Navigation Dock (As seen in the photo)
          FloatingLiquidGlassDock(
            currentIndex: _currentNavIndex,
            onItemSelected: (index) {
              setState(() => _currentNavIndex = index);
            },
          ),

          // Floating Quick Toolbox Button (positioned right above the dock)
          Positioned(
            right: 20,
            bottom: 84,
            child: FloatingToolboxButton(
              onPressed: () => QuickToolboxSheet.show(
                context,
                onAddHabit: () => _showAddHabitDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      backgroundColor: AppColors.cardSurface,
      color: AppColors.accentPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110), // Padding for dock
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Bento Row: 2 Columns Side-by-Side (2026 Progress + LeetCode)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: YearProgressMiniCard(),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: LeetCodeMiniCard(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Full-width GitHub Contributions Card (Matching photo)
            const GitHubActivityCard(),

            const SizedBox(height: 12),

            // 3. Habit Cards with Embedded Heatmaps (Threads, SaaS, Books)
            const HabitsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 110),
      physics: BouncingScrollPhysics(),
      child: HabitsSection(),
    );
  }

  Widget _buildAnalyticsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 110),
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          DeepWorkCard(),
          SizedBox(height: 14),
          WakaTimeStatsCard(),
          SizedBox(height: 14),
          DeveloperBadgesCard(),
          SizedBox(height: 14),
          LeetCodeSummaryCard(),
          SizedBox(height: 14),
          YearProgressCard(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final ghUser = ref.watch(githubUsernameProvider);
    final lcUser = ref.watch(leetCodeUsernameProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Developer Profile Card matching reference design (Obsidian & Sunset)
          const DevProfileCard(),
          const SizedBox(height: 20),
          Text('Settings & Integrations', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.code, color: AppColors.accentPrimary),
            title: const Text('GitHub Handle'),
            subtitle: Text('@$ghUser', style: AppTypography.monoMicro),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _showEditGithubHandleDialog(context, ghUser),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.psychology, color: AppColors.leetCodeMedium),
            title: const Text('LeetCode Handle'),
            subtitle: Text('@$lcUser', style: AppTypography.monoMicro),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _showEditLeetCodeHandleDialog(context, lcUser),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.key_rounded, color: AppColors.accentCyan),
            title: const Text('GitHub Token (PAT)'),
            subtitle: Text(
              DatabaseService.cacheBox.get('github_token') != null
                  ? 'Active (Private commits enabled)'
                  : 'Configure for private contributions',
              style: AppTypography.monoMicro,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              HapticFeedback.lightImpact();
              _showGithubTokenDialog(context);
            },
          ),
          const SizedBox(height: 12),
          // WakaTime Coding Time Integration
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.timer_rounded, color: AppColors.accentCyan),
            title: const Text('WakaTime Integration'),
            subtitle: Text(
              ref.watch(wakatimeApiKeyProvider).isNotEmpty
                  ? 'Active (Live API Connected)'
                  : 'Configure API key or username',
              style: AppTypography.monoMicro,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => WakaTimeSettingsDialog.show(context),
          ),
          const SizedBox(height: 20),
          Text('Data & Backup', style: AppTypography.labelLarge),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.file_download_outlined, color: AppColors.success),
            title: const Text('Export Local Data'),
            subtitle: const Text('Backup habits, check-ins & stats to JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              HapticFeedback.lightImpact();
              _exportDataDialog(context);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.file_upload_outlined, color: AppColors.accentCyan),
            title: const Text('Import Local Data'),
            subtitle: const Text('Restore from JSON backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              HapticFeedback.lightImpact();
              _importDataDialog(context);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            tileColor: AppColors.cardSurface,
            leading: const Icon(Icons.vibration, color: AppColors.accentPurple),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Tactile response on taps and check-ins'),
            trailing: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),
          const SizedBox(height: 32),
          // App Logo Branding & Version
          Center(
            child: Column(
              children: [
                const GitHabitLogo(size: 64, variant: LogoVariant.image),
                const SizedBox(height: 12),
                Text(
                  'GitHabit',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Developer Habit Tracker & Code Pulse',
                  style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder, width: 0.6),
                  ),
                  child: Text(
                    'v1.0.0 • Build with ❤️ for Developers',
                    style: AppTypography.monoMicro.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditGithubHandleDialog(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Edit GitHub Handle', style: AppTypography.titleSmall),
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
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(githubUsernameProvider.notifier).setUsername(newName);
                ref.invalidate(githubActivityProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLeetCodeHandleDialog(BuildContext context, String current) {
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
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(leetCodeUsernameProvider.notifier).setUsername(newName);
                ref.invalidate(leetCodeStatsProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportDataDialog(BuildContext context) {
    final habitsBox = DatabaseService.habitsBox;
    final checkInsBox = DatabaseService.checkInsBox;

    final Map<String, dynamic> checkInsData = {};
    for (final key in checkInsBox.keys) {
      checkInsData[key.toString()] = checkInsBox.get(key);
    }

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habitsBox.values.toList(),
      'checkIns': checkInsData,
      'pomodoroSessions': DatabaseService.pomodoroBox.values.toList(),
      'streakFreeze': ref.read(streakFreezeProvider).value?.toMap(),
      'profile': ref.read(profileProvider).toMap(),
      'github_username': ref.read(githubUsernameProvider),
      'leetcode_username': ref.read(leetCodeUsernameProvider),
    };

    final jsonStr = jsonEncode(data);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Data Backup JSON', style: AppTypography.titleSmall),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: AppTypography.monoMicro.copyWith(fontSize: 10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup copied to clipboard!')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importDataDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Restore from Backup', style: AppTypography.titleSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste your exported JSON backup below:', style: AppTypography.bodySmall),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              style: AppTypography.monoMicro,
              decoration: const InputDecoration(
                hintText: '{"exportedAt": ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final text = controller.text.trim();
                final map = jsonDecode(text) as Map<String, dynamic>;
                await ref.read(habitsProvider.notifier).restoreBackup(map);

                // Restore check-ins
                final checkIns = map['checkIns'] as Map?;
                if (checkIns != null) {
                  for (final key in checkIns.keys) {
                    await DatabaseService.checkInsBox.put(key, checkIns[key]);
                  }
                }

                // Restore Pomodoro sessions
                if (map['pomodoroSessions'] is List) {
                  final pBox = DatabaseService.pomodoroBox;
                  await pBox.clear();
                  for (final item in map['pomodoroSessions']) {
                    if (item is Map && item['id'] != null) {
                      await pBox.put(item['id'], item);
                    }
                  }
                  ref.invalidate(pomodoroProvider);
                }

                // Restore Streak Freeze shields and dates
                if (map['streakFreeze'] is Map) {
                  final freezeRepo = ref.read(freezeRepositoryProvider);
                  await freezeRepo.saveFreezeState(StreakFreezeState.fromMap(map['streakFreeze']));
                  ref.invalidate(streakFreezeProvider);
                }

                // Restore Developer Profile
                if (map['profile'] is Map) {
                  final p = UserProfile.fromMap(map['profile']);
                  await ref.read(profileProvider.notifier).updateProfile(
                    name: p.name,
                    role: p.role,
                    company: p.company,
                    style: p.style,
                    isAvailableForHire: p.isAvailableForHire,
                  );
                }

                if (map['github_username'] != null) {
                  await ref.read(githubUsernameProvider.notifier).setUsername(map['github_username'].toString());
                }
                if (map['leetcode_username'] != null) {
                  await ref.read(leetCodeUsernameProvider.notifier).setUsername(map['leetcode_username'].toString());
                }

                if (ctx.mounted) Navigator.pop(ctx);
                ref.read(habitsProvider.notifier).loadHabits();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup restored successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppColors.error, content: Text('Invalid backup JSON: $e')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showGithubTokenDialog(BuildContext context) {
    final currentToken = DatabaseService.cacheBox.get('github_token') ?? '';
    final controller = TextEditingController(text: currentToken);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('GitHub Personal Access Token', style: AppTypography.titleSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a classic GitHub token (with "repo" and "user" scopes) to include your private repository commits in the heatmap.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              style: AppTypography.monoValue,
              decoration: const InputDecoration(
                hintText: 'ghp_...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentToken.isNotEmpty)
            TextButton(
              onPressed: () async {
                await DatabaseService.cacheBox.delete('github_token');
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(githubActivityProvider);
                setState(() {});
              },
              child: const Text('Remove Token', style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = controller.text.trim();
              if (token.isNotEmpty) {
                await DatabaseService.cacheBox.put('github_token', token);
              } else {
                await DatabaseService.cacheBox.delete('github_token');
              }
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(githubActivityProvider);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

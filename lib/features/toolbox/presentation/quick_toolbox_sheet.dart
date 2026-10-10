import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../freeze/presentation/freeze_provider.dart';
import '../../freeze/presentation/streak_freeze_dialog.dart';
import '../../habits/presentation/habits_provider.dart';
import '../../habits/presentation/streak_provider.dart';
import '../../dashboard/widgets/day_streak_sheet.dart';
import '../../pomodoro/presentation/pomodoro_provider.dart';
import '../../profile/widgets/share_dev_card_dialog.dart';

class QuickToolboxSheet extends ConsumerStatefulWidget {
  final VoidCallback onAddHabit;

  const QuickToolboxSheet({
    super.key,
    required this.onAddHabit,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onAddHabit}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuickToolboxSheet(onAddHabit: onAddHabit),
    );
  }

  @override
  ConsumerState<QuickToolboxSheet> createState() => _QuickToolboxSheetState();
}

class _QuickToolboxSheetState extends ConsumerState<QuickToolboxSheet> {
  bool _showScratchpad = false;
  late final TextEditingController _scratchpadController;

  @override
  void initState() {
    super.initState();
    String savedNote = '';
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        savedNote = DatabaseService.settingsBox.get('githabit_scratchpad') as String? ??
            DatabaseService.settingsBox.get('devpulse_scratchpad') as String? ??
            '';
      }
    } catch (_) {}
    _scratchpadController = TextEditingController(text: savedNote);
  }

  @override
  void dispose() {
    _scratchpadController.dispose();
    super.dispose();
  }

  Future<void> _saveScratchpad() async {
    try {
      if (Hive.isBoxOpen(DatabaseService.settingsBoxName)) {
        await DatabaseService.settingsBox.put('githabit_scratchpad', _scratchpadController.text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider).value ?? [];
    final streakMetrics = ref.watch(streakProvider);
    final allDone = habits.isNotEmpty && habits.every((h) => h.isCompletedToday);
    final freezeState = ref.watch(streakFreezeProvider).value;
    final availableFreezes = freezeState?.availableFreezes ?? 0;

    final pomodoro = ref.watch(pomodoroProvider).value;
    final todayFocus = pomodoro?.todayFormatted ?? '0m';
    final sessionsToday = pomodoro?.completedToday ?? 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: LiquidGlassContainer(
          borderRadius: 32,
          blurSigma: 30,
          backgroundColor: const Color(0xE6161B22), // 90% opaque frosted dark
          borderColor: const Color(0x38FFFFFF),
          borderWidth: 1.2,
          shadows: [
            BoxShadow(
              color: Colors.black.withAlpha(200),
              blurRadius: 36,
              offset: const Offset(0, 10),
            ),
          ],
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Pull indicator handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppColors.accentPrimary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Developer Toolbox',
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Fast Streak Pill link to DayStreakSheet
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      DayStreakSheet.show(context, onAddHabit: widget.onAddHabit);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1C12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF5C331B), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${streakMetrics.currentStreak}d',
                            style: AppTypography.monoBadge.copyWith(
                              color: const Color(0xFFFF8B3D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_showScratchpad) ...[
                // Grid of 4 Fast Actions
                Row(
                  children: [
                    // Action 1: Check in all today
                    Expanded(
                      child: _buildToolCard(
                        icon: allDone ? Icons.check_circle_rounded : Icons.checklist_rounded,
                        title: allDone ? 'All Done!' : 'Check-In All',
                        subtitle: allDone ? 'All completed today' : '1-tap complete',
                        color: allDone ? AppColors.success : AppColors.accentCyan,
                        isActive: allDone,
                        onTap: () async {
                          if (!allDone) {
                            HapticFeedback.heavyImpact();
                            final count = await ref.read(habitsProvider.notifier).checkInAllToday();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Checked in $count habit(s) for today!')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Action 2: Streak Freeze
                    Expanded(
                      child: _buildToolCard(
                        icon: Icons.ac_unit_rounded,
                        title: 'Streak Freeze',
                        subtitle: '$availableFreezes shield${availableFreezes == 1 ? '' : 's'}',
                        color: const Color(0xFF38BDF8),
                        onTap: () {
                          Navigator.pop(context);
                          StreakFreezeDialog.show(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // Action 3: Log Deep Work (25m)
                    Expanded(
                      child: _buildToolCard(
                        icon: Icons.timer_outlined,
                        title: 'Log Deep Work (25m)',
                        subtitle: '$todayFocus ($sessionsToday done)',
                        color: AppColors.accentPurple,
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(pomodoroProvider.notifier).recordSession(25, tag: 'Coding');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('+25m Deep Work focus logged! ⚡')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Action 4: Share Dev Card
                    Expanded(
                      child: _buildToolCard(
                        icon: Icons.qr_code_2_rounded,
                        title: 'Share Dev Card',
                        subtitle: 'Profile & badges',
                        color: const Color(0xFFFF5C77),
                        onTap: () {
                          Navigator.pop(context);
                          ShareDevCardDialog.show(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row with Scratchpad & New Habit
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.note_alt_outlined, size: 16),
                        label: const Text('Dev Scratchpad'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => setState(() => _showScratchpad = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Habit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onAddHabit();
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Dev Scratchpad View
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scratchpad / Quick Notes', style: AppTypography.labelLarge),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 14),
                      label: const Text('Back to Tools'),
                      onPressed: () => setState(() => _showScratchpad = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _scratchpadController,
                  maxLines: 6,
                  style: AppTypography.monoMicro.copyWith(fontSize: 12),
                  onChanged: (_) => _saveScratchpad(),
                  decoration: InputDecoration(
                    hintText: 'Jot down bugs, code snippets, or ideas...',
                    hintStyle: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardSurfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Auto-saved locally in Hive',
                    style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(35) : color.withAlpha(18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? color : color.withAlpha(60),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoMicro.copyWith(
                  color: isActive ? color : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

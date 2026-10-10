import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../automation/presentation/automation_provider.dart';
import '../../habits/domain/streak_calculator.dart';
import 'freeze_provider.dart';

class StreakFreezeDialog extends ConsumerWidget {
  const StreakFreezeDialog({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      builder: (_) => const StreakFreezeDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freezeState = ref.watch(streakFreezeProvider).value;
    final available = freezeState?.availableFreezes ?? 0;
    final frozenDates = freezeState?.frozenDates ?? [];

    final now = DateTime.now();
    final today = StreakCalculator.normalizeDate(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    final isTodayFrozen = freezeState?.isDateFrozen(today) ?? false;
    final isYesterdayFrozen = freezeState?.isDateFrozen(yesterday) ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Deep navy frost background
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF38BDF8).withAlpha(120), // Cyan icy border
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withAlpha(80),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Frost Icon
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF38BDF8),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Text('❄️', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Freeze Shield',
                        style: AppTypography.titleSmall.copyWith(
                          color: const Color(0xFFF0F9FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$available shield${available == 1 ? '' : 's'} available',
                        style: AppTypography.monoMicro.copyWith(
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
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
            const SizedBox(height: 18),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withAlpha(160),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha(20),
                ),
              ),
              child: Text(
                'Streak Freezes protect your coding streaks! If life happens and you cannot code today, a shield will keep your streak counter unbroken.',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFFCBD5E1),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Action Cards
            // 1. Protect Today
            _buildActionRow(
              context: context,
              ref: ref,
              title: 'Protect Today',
              subtitle: isTodayFrozen ? 'Shield is currently ACTIVE' : 'Keep streak intact for today',
              isActive: isTodayFrozen,
              canActivate: available > 0 && !isTodayFrozen,
              onToggle: () async {
                HapticFeedback.mediumImpact();
                if (isTodayFrozen) {
                  await ref.read(streakFreezeProvider.notifier).unfreezeDate(today);
                } else {
                  await ref.read(streakFreezeProvider.notifier).freezeDate(today);
                }
              },
            ),
            const SizedBox(height: 10),

            // 2. Protect Yesterday
            _buildActionRow(
              context: context,
              ref: ref,
              title: 'Shield Yesterday',
              subtitle: isYesterdayFrozen ? 'Shield is currently ACTIVE' : 'Repair broken chain from yesterday',
              isActive: isYesterdayFrozen,
              canActivate: available > 0 && !isYesterdayFrozen,
              onToggle: () async {
                HapticFeedback.mediumImpact();
                if (isYesterdayFrozen) {
                  await ref.read(streakFreezeProvider.notifier).unfreezeDate(yesterday);
                } else {
                  await ref.read(streakFreezeProvider.notifier).freezeDate(yesterday);
                }
              },
            ),
            const SizedBox(height: 12),

            // 3. Smart Auto-Freeze Switch
            _buildAutoFreezeSwitch(context: context, ref: ref),

            if (frozenDates.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Protected Dates (${frozenDates.length})',
                style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: frozenDates.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0369A1).withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0284C7)),
                    ),
                    child: Text(
                      '❄️ $d',
                      style: AppTypography.monoMicro.copyWith(
                        color: const Color(0xFFBAE6FD),
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            // Bottom Earn Shields Note
            Row(
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tip: Every 7-day streak milestone rewards +1 Freeze shield!',
                    style: AppTypography.monoMicro.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool canActivate,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF0369A1).withAlpha(35)
            : const Color(0xFF1E293B).withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF38BDF8) : Colors.white.withAlpha(25),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.shield_rounded : Icons.shield_outlined,
            color: isActive ? const Color(0xFF38BDF8) : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 13,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.monoMicro.copyWith(
                    color: isActive ? const Color(0xFF38BDF8) : AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: (isActive || canActivate) ? onToggle : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive
                  ? const Color(0xFFDC2626) // Red to remove/cancel shield
                  : const Color(0xFF0284C7), // Blue to activate
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isActive ? 'Remove' : 'Activate',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoFreezeSwitch({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final settings = ref.watch(automationSettingsProvider).value;
    final isAutoFreeze = settings?.isAutoFreezeEnabled ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(140),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAutoFreeze
              ? const Color(0xFF38BDF8).withAlpha(120)
              : Colors.white.withAlpha(20),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🛡️', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Smart Auto-Rescue',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AI / AUTO',
                        style: AppTypography.monoMicro.copyWith(
                          fontSize: 9,
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Auto-freeze missed days when shields exist',
                  style: AppTypography.monoMicro.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAutoFreeze,
            activeThumbColor: const Color(0xFF38BDF8),
            activeTrackColor: const Color(0xFF38BDF8).withAlpha(100),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.black26,
            onChanged: (_) async {
              HapticFeedback.lightImpact();
              await ref.read(automationSettingsProvider.notifier).toggleAutoFreeze();
            },
          ),
        ],
      ),
    );
  }
}



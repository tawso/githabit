import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/automation_models.dart';
import 'automation_provider.dart';

class AutomationSettingsDialog extends ConsumerWidget {
  const AutomationSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      builder: (_) => const AutomationSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(automationSettingsProvider);
    final eventsAsync = ref.watch(automationEventsProvider);
    final settings = settingsAsync.value ?? const AutomationSettings();
    final events = eventsAsync.value ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Deep navy / obsidian slate
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF22C55E).withAlpha(100), // Neon emerald border
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withAlpha(50),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withAlpha(35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Text('⚡', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automation Engine',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Zero-effort streak & habit tracking',
                          style: AppTypography.monoMicro.copyWith(
                            color: const Color(0xFF22C55E),
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

              // Description banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(160),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Text(
                  'Automations eliminate manual logging by reacting to GitHub commits, auto-shielding streaks before midnight, and sending timely briefings.',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFCBD5E1),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Toggle 1: Auto-Checkin
              _buildAutomationToggle(
                icon: '🚀',
                title: 'GitHub Auto-Checkin',
                subtitle: 'Auto-completes coding habits upon detecting commits or contributions.',
                value: settings.isAutoCheckinEnabled,
                accentColor: const Color(0xFF22C55E),
                onChanged: (_) async {
                  HapticFeedback.lightImpact();
                  await ref.read(automationSettingsProvider.notifier).toggleAutoCheckin();
                },
              ),
              const SizedBox(height: 10),

              // Toggle 2: Smart Auto-Freeze
              _buildAutomationToggle(
                icon: '🛡️',
                title: 'Smart Streak Shield',
                subtitle: 'Auto-freezes yesterday if you miss a day so your momentum is never lost.',
                value: settings.isAutoFreezeEnabled,
                accentColor: const Color(0xFF38BDF8),
                onChanged: (_) async {
                  HapticFeedback.lightImpact();
                  await ref.read(automationSettingsProvider.notifier).toggleAutoFreeze();
                },
              ),
              const SizedBox(height: 10),

              // Toggle 3: Smart Notifications
              _buildAutomationToggle(
                icon: '🔔',
                title: 'Smart Notifications',
                subtitle: 'Morning briefing at 09:00 & evening deadline warning at 21:00.',
                value: settings.isSmartNotificationsEnabled,
                accentColor: const Color(0xFFFBBF24),
                onChanged: (_) async {
                  HapticFeedback.lightImpact();
                  await ref.read(automationSettingsProvider.notifier).toggleSmartNotifications();
                },
              ),
              const SizedBox(height: 20),

              // Manual trigger button
              OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  ref.invalidate(automationEvaluationProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0F172A),
                        content: Row(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'Automation engine evaluated!',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x7822C55E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.sync_rounded, color: Color(0xFF22C55E), size: 18),
                label: Text(
                  'Run Automation Check Now',
                  style: AppTypography.labelMedium.copyWith(
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Activity Log Section
              Text(
                'Recent Automation Log (${events.length})',
                style: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),

              if (events.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No automation events yet. They will appear here when triggered!',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.take(5).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final ev = events[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withAlpha(120),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_iconForType(ev.type), style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ev.message,
                                  style: AppTypography.monoMicro.copyWith(
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutomationToggle({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? accentColor.withAlpha(120) : Colors.white.withAlpha(15),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withAlpha(100),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.black26,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _iconForType(AutomationEventType type) {
    switch (type) {
      case AutomationEventType.autoCheckin:
        return '⚡';
      case AutomationEventType.autoFreeze:
        return '🛡️';
      case AutomationEventType.streakWarning:
        return '🔥';
      case AutomationEventType.morningBriefing:
        return '🌅';
      case AutomationEventType.milestone:
        return '🏆';
    }
  }
}

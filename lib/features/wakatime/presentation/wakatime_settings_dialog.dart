import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'wakatime_provider.dart';

class WakaTimeSettingsDialog extends ConsumerStatefulWidget {
  const WakaTimeSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: context,
      builder: (_) => const WakaTimeSettingsDialog(),
    );
  }

  @override
  ConsumerState<WakaTimeSettingsDialog> createState() => _WakaTimeSettingsDialogState();
}

class _WakaTimeSettingsDialogState extends ConsumerState<WakaTimeSettingsDialog> {
  late final TextEditingController _keyController;
  late final TextEditingController _userController;
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(wakatimeApiKeyProvider);
    final currentUser = ref.read(wakatimeUsernameProvider);
    _keyController = TextEditingController(text: currentKey);
    _userController = TextEditingController(text: currentUser);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _saveAndConnect() async {
    final key = _keyController.text.trim();
    final user = _userController.text.trim();

    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    try {
      await ref.read(wakatimeApiKeyProvider.notifier).setApiKey(key);
      await ref.read(wakatimeUsernameProvider.notifier).setUsername(user);

      // Force refresh stats
      final repo = ref.read(wakatimeRepositoryProvider);
      final stats = await repo.getStats(
        apiKey: key.isNotEmpty ? key : null,
        username: user.isNotEmpty ? user : null,
        forceRefresh: true,
      );

      ref.invalidate(wakatimeStatsProvider);

      if (mounted) {
        setState(() {
          _isTesting = false;
          _isSuccess = true;
          _statusMessage = stats.isMock
              ? 'Saved in demo mode (no key provided).'
              : 'Connected successfully! Coding time: ${stats.humanReadableWeek}';
        });

        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _isSuccess = false;
          _statusMessage = 'Connection failed: $e';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    HapticFeedback.selectionClick();
    await ref.read(wakatimeApiKeyProvider.notifier).clearApiKey();
    await ref.read(wakatimeUsernameProvider.notifier).setUsername('');
    ref.invalidate(wakatimeStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WakaTime disconnected. Reset to realistic demo mode.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = ref.watch(wakatimeApiKeyProvider);
    final isConnected = currentKey.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(200),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
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
                      color: AppColors.accentCyan.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timer_rounded, color: AppColors.accentCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WakaTime Integration', style: AppTypography.titleSmall),
                        Text(
                          'Track IDE coding metrics',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.success.withAlpha(25)
                      : AppColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.success.withAlpha(120)
                        : AppColors.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isConnected ? 'Status: Active (API Key connected)' : 'Status: Demo Mode (Realistic sample data)',
                        style: AppTypography.monoMicro.copyWith(
                          color: isConnected ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Key Field
              Text('WakaTime Secret API Key', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                style: AppTypography.monoBadge.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'waka_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                  hintStyle: AppTypography.monoMicro.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardSurfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find your API key at wakatime.com → Settings → API Key',
                style: AppTypography.monoMicro.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 14),

              // Username Field (Optional alternative)
              Text('WakaTime Username (Optional)', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              TextField(
                controller: _userController,
                style: AppTypography.bodySmall,
                decoration: InputDecoration(
                  hintText: 'e.g. your_wakatime_username',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardSurfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppColors.success.withAlpha(30)
                        : const Color(0xFFFF5C77).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: AppTypography.monoMicro.copyWith(
                      color: _isSuccess ? AppColors.success : const Color(0xFFFF5C77),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Actions Row
              Row(
                children: [
                  if (isConnected) ...[
                    OutlinedButton(
                      onPressed: _disconnect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5C77),
                        side: const BorderSide(color: Color(0x66FF5C77)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Disconnect'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isTesting ? null : _saveAndConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isTesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


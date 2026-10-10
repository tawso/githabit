import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/contribution_heatmap.dart';
import '../domain/habit.dart';
import '../domain/streak_calculator.dart';
import 'habits_provider.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final HabitUiModel initialModel;

  const HabitDetailScreen({super.key, required this.initialModel});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitsProvider);
    final habitId = widget.initialModel.habit.id;

    // Find live updated model from provider
    final currentModel = habitsState.value?.firstWhere(
          (h) => h.habit.id == habitId,
          orElse: () => widget.initialModel,
        ) ??
        widget.initialModel;

    final habit = currentModel.habit;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(habit.title, style: AppTypography.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit habit',
            onPressed: () => _showEditHabitDialog(context, habit),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete habit',
            onPressed: () => _confirmDelete(context, habitId, habit.title),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card: Category, Streak, and Check-In Action
            BentoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: habit.color.withAlpha(35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(habit.category.icon, size: 24, color: habit.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.title, style: AppTypography.titleMedium),
                            if (habit.description != null && habit.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(habit.description!, style: AppTypography.bodySmall),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4 Summary Metrics Pills
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'Current Streak',
                        value: '🔥 ${currentModel.streak}d',
                        color: AppColors.fireStreak,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        label: 'Best Streak',
                        value: '⚡ ${currentModel.longestStreak}d',
                        color: AppColors.accentCyan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'Status Today',
                        value: currentModel.isCompletedToday ? '✓ Done' : 'Pending',
                        color: currentModel.isCompletedToday
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        label: 'Goal Freq.',
                        value: '${habit.targetDaysPerWeek}d / week',
                        color: AppColors.accentPrimary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quick Toggle Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(habitsProvider.notifier).toggleCheckIn(habitId);
                      },
                      icon: Icon(
                        currentModel.isCompletedToday
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      label: Text(
                        currentModel.isCompletedToday
                            ? 'Completed Today (Tap to undo)'
                            : 'Mark as Completed Today',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentModel.isCompletedToday
                            ? habit.color
                            : AppColors.cardSurfaceLight,
                        foregroundColor: currentModel.isCompletedToday
                            ? Colors.white
                            : AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: currentModel.isCompletedToday
                                ? habit.color
                                : AppColors.cardBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Annual Activity Matrix Heatmap
            BentoCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Historical Heatmap', style: AppTypography.titleSmall),
                      Text('Last 140 Days', style: AppTypography.monoMicro),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ContributionHeatmap(
                    datasets: _getHabitContributions(currentModel),
                    colorScale: [
                      const Color(0xFF21262D),
                      habit.color.withAlpha(80),
                      habit.color.withAlpha(140),
                      habit.color.withAlpha(200),
                      habit.color,
                    ],
                    cellSize: 12,
                    cellSpacing: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Interactive Calendar Month (Retroactive check-ins)
            BentoCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_focusedMonth),
                        style: AppTypography.titleSmall,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _focusedMonth = DateTime(
                                  _focusedMonth.year,
                                  _focusedMonth.month - 1,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 14),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _focusedMonth = DateTime(
                                  _focusedMonth.year,
                                  _focusedMonth.month + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInteractiveMonthCalendar(habitId, currentModel),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.monoMicro),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.monoValue.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMonthCalendar(
    String habitId,
    HabitUiModel currentModel,
  ) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfWeek = DateTime(year, month, 1).weekday; // 1 = Mon

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final habit = currentModel.habit;
    final activityMap = _getHabitContributions(currentModel);

    return Column(
      children: [
        // Day Names Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  d,
                  style: AppTypography.monoMicro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: (firstDayOfWeek - 1) + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstDayOfWeek - 1) {
              return const SizedBox.shrink();
            }

            final day = index - (firstDayOfWeek - 1) + 1;
            final date = DateTime(year, month, day);
            final isFuture = date.isAfter(today);
            final isDone = (activityMap[date] ?? 0) > 0;
            final isToday = date == today;

            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      ref.read(habitsProvider.notifier).toggleCheckIn(habitId, date);
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: isDone
                      ? habit.color
                      : (isFuture
                          ? AppColors.cardSurfaceLight.withAlpha(80)
                          : AppColors.cardSurfaceLight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday
                        ? AppColors.accentPrimary
                        : (isDone ? habit.color : AppColors.cardBorder.withAlpha(80)),
                    width: isToday ? 1.5 : 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$day',
                        style: AppTypography.monoMicro.copyWith(
                          color: isFuture
                              ? AppColors.textMuted.withAlpha(90)
                              : (isToday ? AppColors.accentPrimary : AppColors.textPrimary),
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Map<DateTime, int> _getHabitContributions(HabitUiModel model) {
    return StreakCalculator.toContributionMap(model.checkInDates);
  }

  void _confirmDelete(BuildContext context, String habitId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Delete Habit', style: AppTypography.titleSmall),
        content: Text('Are you sure you want to delete "$title"?', style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(habitsProvider.notifier).deleteHabit(habitId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
    HapticFeedback.selectionClick();
    final titleController = TextEditingController(text: habit.title);
    final descController = TextEditingController(text: habit.description ?? '');
    HabitCategory selectedCategory = habit.category;
    int targetDays = habit.targetDaysPerWeek;

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
                  Text('Edit Habit', style: AppTypography.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                maxLength: 80,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Habit Title',
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
                  labelText: 'Description',
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Target Days Per Week', style: AppTypography.labelSmall),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: targetDays > 1
                            ? () => setModalState(() => targetDays--)
                            : null,
                      ),
                      Text('$targetDays', style: AppTypography.monoMetric.copyWith(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: targetDays < 7
                            ? () => setModalState(() => targetDays++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      final updated = habit.copyWith(
                        title: title,
                        description: descController.text.trim(),
                        category: selectedCategory,
                        targetDaysPerWeek: targetDays,
                      );
                      ref.read(habitsProvider.notifier).updateHabit(updated);
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
                  child: const Text('Save Changes'),
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
}

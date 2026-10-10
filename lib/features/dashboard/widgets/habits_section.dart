import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_habit_item.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/streak_calculator.dart';
import '../../habits/presentation/habit_detail_screen.dart';
import '../../habits/presentation/habits_provider.dart';

enum HabitViewMode { single, weekly, yearly }

class HabitsSection extends ConsumerStatefulWidget {
  const HabitsSection({super.key});

  @override
  ConsumerState<HabitsSection> createState() => _HabitsSectionState();
}

class _HabitsSectionState extends ConsumerState<HabitsSection> {
  HabitViewMode _viewMode = HabitViewMode.yearly;
  String _searchQuery = '';
  HabitCategory? _selectedCategory;
  bool _onlyPending = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  HabitCardDisplayMode _toDisplayMode(HabitViewMode mode) {
    switch (mode) {
      case HabitViewMode.single:
        return HabitCardDisplayMode.single;
      case HabitViewMode.weekly:
        return HabitCardDisplayMode.weekly;
      case HabitViewMode.yearly:
        return HabitCardDisplayMode.yearly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Segmented View Switcher (Matching Image 5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Habits', style: AppTypography.titleLarge),
            _buildSegmentedSwitcher(),
          ],
        ),

        const SizedBox(height: 12),

        // Search Bar (Matching Image 4)
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search habits...',
              hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Horizontal Category Filter Chips & Pending Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // All Chip
              _buildFilterChip(
                label: 'All',
                isSelected: _selectedCategory == null && !_onlyPending,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = null;
                    _onlyPending = false;
                  });
                },
              ),
              const SizedBox(width: 8),

              // Pending Only Chip
              _buildFilterChip(
                label: '⚡ Pending',
                isSelected: _onlyPending,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _onlyPending = !_onlyPending;
                  });
                },
              ),
              const SizedBox(width: 8),

              // Category Chips
              for (final cat in HabitCategory.values) ...[
                _buildFilterChip(
                  label: cat.label,
                  icon: cat.icon,
                  iconColor: cat.color,
                  isSelected: _selectedCategory == cat,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = _selectedCategory == cat ? null : cat;
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Habits Bento List
        habitsAsync.when(
          data: (habits) {
            // Apply search & category filters
            final filtered = habits.where((item) {
              if (_searchQuery.isNotEmpty &&
                  !item.habit.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return false;
              }
              if (_selectedCategory != null &&
                  item.habit.category != _selectedCategory) {
                return false;
              }
              if (_onlyPending && item.isCompletedToday) {
                return false;
              }
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    habits.isEmpty
                        ? 'No habits active yet. Tap "+" below to track a habit.'
                        : 'No habits match your filter.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final item in filtered) ...[
                  Builder(
                    builder: (context) {
                      final daysSinceCreation =
                          DateTime.now().difference(item.habit.createdAt).inDays + 1;
                      final totalDays = math.max(
                        daysSinceCreation,
                        math.max(item.longestStreak, item.checkInDates.length),
                      );
                      return BentoHabitItem(
                        title: item.habit.title,
                        icon: item.habit.category.icon,
                        categoryColor: item.habit.color,
                        streak: item.streak,
                        totalDays: totalDays,
                        isCompletedToday: item.isCompletedToday,
                        activityData:
                            StreakCalculator.toContributionMap(item.checkInDates),
                        displayMode: _toDisplayMode(_viewMode),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HabitDetailScreen(initialModel: item),
                            ),
                          );
                        },
                        onToggle: (_) {
                          ref
                              .read(habitsProvider.notifier)
                              .toggleCheckIn(item.habit.id);
                        },
                        onToggleDate: (date) {
                          ref
                              .read(habitsProvider.notifier)
                              .toggleCheckIn(item.habit.id, date);
                        },
                        onDelete: () =>
                            _confirmDelete(context, item.habit.id, item.habit.title),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, _) => Text(
            'Error loading habits: $err',
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary.withAlpha(45) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.cardBorder,
            width: isSelected ? 1.0 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: iconColor ?? AppColors.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.monoMicro.copyWith(
                color: isSelected ? AppColors.accentPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentTab(
              HabitViewMode.single, 'Single', Icons.view_headline_rounded),
          _buildSegmentTab(
              HabitViewMode.weekly, 'Weekly', Icons.calendar_view_week_rounded),
          _buildSegmentTab(
              HabitViewMode.yearly, 'Yearly', Icons.grid_view_rounded),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(HabitViewMode mode, String label, IconData icon) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _viewMode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardSurfaceHover : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.monoMicro.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String habitId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Delete Habit', style: AppTypography.titleSmall),
        content: Text('Delete "$title"? This cannot be undone.',
            style: AppTypography.bodySmall),
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
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

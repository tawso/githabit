import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:githabit/core/widgets/bento_card.dart';
import 'package:githabit/core/widgets/bento_habit_item.dart';
import 'package:githabit/core/widgets/contribution_heatmap.dart';
import 'package:githabit/core/widgets/floating_liquid_glass_dock.dart';
import 'package:githabit/core/widgets/leetcode_ring_chart.dart';
import 'package:githabit/core/widgets/year_progress_grid.dart';
import 'package:githabit/features/dashboard/widgets/deep_work_card.dart';
import 'package:githabit/features/dashboard/widgets/developer_badges_card.dart';
import 'package:githabit/features/dashboard/widgets/year_progress_card.dart';
import 'package:githabit/features/profile/widgets/dev_profile_card.dart';
import 'package:githabit/features/profile/domain/user_profile.dart';
import 'package:githabit/features/profile/presentation/profile_provider.dart';
import 'package:githabit/features/profile/widgets/share_dev_card_dialog.dart';
import 'package:githabit/features/freeze/presentation/streak_freeze_dialog.dart';
import 'package:githabit/features/toolbox/presentation/quick_toolbox_sheet.dart';
import 'package:githabit/features/toolbox/widgets/floating_toolbox_button.dart';
import 'package:githabit/features/dashboard/widgets/day_streak_card.dart';

void main() {
  testWidgets('BentoCard renders child properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BentoCard(
            child: Text('Test Bento Card'),
          ),
        ),
      ),
    );

    expect(find.text('Test Bento Card'), findsOneWidget);
  });

  testWidgets('LeetCodeRingChart renders solved statistics', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LeetCodeRingChart(
            easySolved: 50,
            mediumSolved: 30,
            hardSolved: 10,
          ),
        ),
      ),
    );

    expect(find.text('90'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
  });

  testWidgets('ContributionHeatmap renders custom paint canvas', (WidgetTester tester) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContributionHeatmap(
            datasets: {
              DateTime(today.year, today.month, today.day): 5,
            },
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Tap a day for details'), findsOneWidget);
  });

  testWidgets('YearProgressGrid renders matrix and percentages', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: YearProgressGrid(
              currentDate: DateTime(2026, 7, 2),
            ),
          ),
        ),
      ),
    );

    expect(find.text('2026'), findsOneWidget);
    expect(find.textContaining('d left'), findsOneWidget);
  });

  testWidgets('FloatingLiquidGlassDock renders items and responds to taps', (WidgetTester tester) async {
    int selectedTab = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingLiquidGlassDock(
            currentIndex: selectedTab,
            onItemSelected: (index) => selectedTab = index,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Habits'));
    await tester.pump();
    expect(selectedTab, 1);
  });

  testWidgets('YearProgressMiniCard renders dynamic percentage and dots', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: YearProgressMiniCard(),
        ),
      ),
    );

    expect(find.textContaining('Progress'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('BentoHabitItem renders in weekly and yearly modes without errors', (WidgetTester tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BentoHabitItem(
                title: 'Post on Threads',
                icon: Icons.chat_bubble_outline,
                streak: 50,
                totalDays: 156,
                isCompletedToday: true,
                displayMode: HabitCardDisplayMode.weekly,
                activityData: {
                  DateTime(now.year, now.month, now.day): 1,
                },
                onToggle: (_) {},
              ),
              BentoHabitItem(
                title: 'SaaS Work',
                icon: Icons.code,
                streak: 104,
                totalDays: 156,
                isCompletedToday: false,
                displayMode: HabitCardDisplayMode.yearly,
                activityData: {
                  DateTime(now.year, now.month, now.day): 1,
                },
                onToggle: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Post on Threads'), findsOneWidget);
    expect(find.text('SaaS Work'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('104'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
  });

  testWidgets('DeepWorkCard renders Pomodoro timer controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DeepWorkCard(),
          ),
        ),
      ),
    );

    expect(find.text('Deep Work Pomodoro'), findsOneWidget);
    expect(find.text('25m'), findsOneWidget);
    expect(find.text('50m'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('FloatingLiquidGlassDock and DeveloperBadgesCard render without overflow on narrow width (300px)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const SingleChildScrollView(
                  child: DeveloperBadgesCard(),
                ),
                FloatingLiquidGlassDock(
                  currentIndex: 0,
                  onItemSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Dev Badges & Honors'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DevProfileCard renders in Obsidian mode without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DevProfileCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Software Engineer'), findsOneWidget);
    expect(find.text('Get In Touch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DevProfileCard renders in Liquid Sunset mode without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(_SunsetMockProfileNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DevProfileCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Devin Vance'), findsOneWidget);
    expect(find.text('Principal Engineer'), findsOneWidget);
    expect(find.text('Get In Touch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StreakFreezeDialog renders and displays shields info', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StreakFreezeDialog(),
          ),
        ),
      ),
    );

    expect(find.text('Streak Freeze Shield'), findsOneWidget);
    expect(find.text('Protect Today'), findsOneWidget);
    expect(find.text('Shield Yesterday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShareDevCardDialog renders export options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ShareDevCardDialog(),
          ),
        ),
      ),
    );

    expect(find.text('Share Dev Card'), findsOneWidget);
    expect(find.text('Capture HD Card (PNG)'), findsOneWidget);
    expect(find.text('Copy Portfolio Text'), findsOneWidget);
    expect(find.text('Copy GitHub README Badge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FloatingToolboxButton and QuickToolboxSheet render shortcuts properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingToolboxButton(onPressed: () {}),
                QuickToolboxSheet(onAddHabit: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Toolbox'), findsOneWidget);
    expect(find.text('Quick Developer Toolbox'), findsOneWidget);
    expect(find.text('Streak Freeze'), findsOneWidget);
    expect(find.text('Share Dev Card'), findsOneWidget);
    expect(find.text('Dev Scratchpad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DayStreakCard renders glowing flame, 7-day circular tracker and progress', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DayStreakCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('DAYS'), findsOneWidget);
    expect(find.text('DAILY DEV GOAL'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SunsetMockProfileNotifier extends ProfileNotifier {
  @override
  UserProfile build() {
    return const UserProfile(
      name: 'Devin Vance',
      role: 'Principal Engineer',
      company: 'Meta Lab',
      style: ProfileCardStyle.liquidSunset,
    );
  }
}

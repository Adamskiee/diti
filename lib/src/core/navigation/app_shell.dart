import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/history/domain/draft_session.dart';
import '../../features/history/presentation/history_analytics_screen.dart';
import '../../features/history/presentation/widgets/session_verification_sheet.dart';
import '../../features/history/providers/history_providers.dart';
import '../../features/plan/presentation/plan_screen.dart';
import '../../features/routines/presentation/routine_editor_screen.dart';
import '../../features/routines/presentation/routine_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/timer/controllers/active_timer_controller.dart';
import '../../features/timer/presentation/active_timer_screen.dart';
import '../../features/timer/presentation/widgets/active_timer_mini_player.dart';
import '../di/timer_engine_provider.dart';
import 'app_tab.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  AppTab _currentTab = AppTab.routines;
  bool _isVerificationSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize coordinator & recovery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(timerLifecycleCoordinatorProvider).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final coordinator = ref.read(timerLifecycleCoordinatorProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      coordinator.onPause();
    } else if (state == AppLifecycleState.resumed) {
      coordinator.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(activeTimerControllerProvider);

    ref.listen<DraftSessionState>(
      sessionVerificationControllerProvider,
      (prev, next) {
        if (next.isVisible &&
            (prev == null || !prev.isVisible) &&
            !_isVerificationSheetOpen) {
          _isVerificationSheetOpen = true;
          showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            enableDrag: false,
            isScrollControlled: true,
            builder: (ctx) => const SessionVerificationSheet(),
          ).whenComplete(() {
            _isVerificationSheetOpen = false;
          });
        }
      },
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          RoutineListScreen(
            onStartRoutine: (routine) async {
              final result = await ref
                  .read(activeTimerControllerProvider.notifier)
                  .startRoutine(routine.id);
              if (!context.mounted) return;
              if (result.success) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => const ActiveTimerScreen(),
                    fullscreenDialog: true,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.error?.name ?? 'Failed to start routine',
                    ),
                  ),
                );
              }
            },
            onEditRoutine: (routineId) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => RoutineEditorScreen(routineId: routineId),
                ),
              );
            },
          ),
          const PlanScreen(),
          const HistoryAnalyticsScreen(),
          SettingsScreen(key: ValueKey(_currentTab == AppTab.settings)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (timerState.isActive) const ActiveTimerMiniPlayer(),
          NavigationBar(
            selectedIndex: _currentTab.index,
            onDestinationSelected: (idx) {
              setState(() => _currentTab = AppTab.values[idx]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: 'Routines',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Plan',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

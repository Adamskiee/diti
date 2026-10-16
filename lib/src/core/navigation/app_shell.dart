import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _buildPlaceholder(
            title: 'Daily Plan',
            description: 'Coming in Phase 4B: Time-blocking and schedule routines.',
            icon: Icons.calendar_today,
          ),
          _buildPlaceholder(
            title: 'History & Analytics',
            description: 'Coming in Phase 4C: Session history and productivity metrics.',
            icon: Icons.history,
          ),
          const SettingsScreen(),
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

  Widget _buildPlaceholder({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

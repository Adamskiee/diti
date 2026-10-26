import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/active_timer_controller.dart';
import 'widgets/circular_timer_dial.dart';

class ActiveTimerScreen extends ConsumerWidget {
  const ActiveTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeTimerControllerProvider);
    final controller = ref.read(activeTimerControllerProvider.notifier);
    final theme = Theme.of(context);

    final isCompleted = state.status == RunStatus.completed;
    final isPaused = state.status == RunStatus.paused;
    final isAwaitingAction = state.isAwaitingAction;

    final dialColor = isCompleted
        ? theme.colorScheme.primary
        : (isPaused
            ? AppColors.pausedAmber
            : (isAwaitingAction
                ? AppColors.awaitingActionPulse
                : theme.colorScheme.primary));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          tooltip: 'Minimize',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(state.phaseName.isEmpty ? 'Timer' : state.phaseName),
        actions: [
          if (!isCompleted)
            IconButton(
              key: const Key('timer_stop_button'),
              icon: const Icon(Icons.close),
              tooltip: 'Stop Routine',
              onPressed: () => _handleStop(context, controller),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.cycleDescription.isNotEmpty)
                Text(
                  state.cycleDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 24),
              CircularTimerDial(
                progress: state.progress,
                formattedTime: state.formattedTime,
                primaryColor: dialColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 24),
              if (isCompleted)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Routine Complete! Great work.',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isPaused)
                const Chip(
                  avatar: Icon(Icons.pause, size: 16),
                  label: Text('PAUSED'),
                  backgroundColor: AppColors.pausedAmber,
                )
              else if (isAwaitingAction)
                const Chip(
                  avatar: Icon(Icons.touch_app, size: 16),
                  label: Text('COMPLETED — READY TO CONTINUE'),
                  backgroundColor: AppColors.awaitingActionPulse,
                )
              else
                Chip(
                  label: Text(state.isCountdown ? 'Focusing' : 'Open Flow'),
                ),
              if (state.nextPhasePreview != null && !isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  'Next: ${state.nextPhasePreview}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 36),
              if (isCompleted) ...[
                FilledButton.icon(
                  key: const Key('timer_done_button'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                ),
              ] else if (isAwaitingAction) ...[
                FilledButton.icon(
                  onPressed: () => controller.finishPhase(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Start Next Phase'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      tooltip: 'Skip Phase',
                      icon: const Icon(Icons.skip_next),
                      onPressed: () => controller.skipPhase(),
                    ),
                    const SizedBox(width: 24),
                    FloatingActionButton.large(
                      key: const Key('timer_play_pause_button'),
                      onPressed: () {
                        if (isPaused) {
                          controller.resume();
                        } else {
                          controller.pause();
                        }
                      },
                      child: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    ),
                    const SizedBox(width: 24),
                    IconButton.outlined(
                      tooltip: 'Finish Phase',
                      icon: const Icon(Icons.check),
                      onPressed: () => controller.finishPhase(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleStop(BuildContext context, ActiveTimerController controller) async {
    final nav = Navigator.of(context);
    nav.pop();
    await controller.stop();
  }
}

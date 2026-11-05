import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../controllers/active_timer_controller.dart';
import '../active_timer_screen.dart';

class ActiveTimerMiniPlayer extends ConsumerWidget {
  const ActiveTimerMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeTimerControllerProvider);
    if (!state.isActive) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(activeTimerControllerProvider.notifier);
    final theme = Theme.of(context);
    final isPaused = state.status == RunStatus.paused;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: state.progress,
            minHeight: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  key: const Key('mini_player_toggle_button'),
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: () {
                    if (isPaused) {
                      controller.resume();
                    } else {
                      controller.pause();
                    }
                  },
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => const ActiveTimerScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.phaseName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (state.cycleDescription.isNotEmpty)
                                  Text(
                                    state.cycleDescription,
                                    style: theme.textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            state.formattedTime,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/history_providers.dart';
import 'session_detail_sheet.dart';
import 'session_feed_tile.dart';

class HistoryFeedView extends ConsumerWidget {
  const HistoryFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feedState = ref.watch(historyFeedControllerProvider);
    final activeFilter = ref.watch(historyFeedFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: activeFilter == HistoryOutcomeFilter.all,
                onSelected: (_) {
                  ref.read(historyFeedFilterProvider.notifier).state =
                      HistoryOutcomeFilter.all;
                  ref
                      .read(historyFeedControllerProvider.notifier)
                      .setFilter(HistoryOutcomeFilter.all);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Completed'),
                selected: activeFilter == HistoryOutcomeFilter.completed,
                onSelected: (_) {
                  ref.read(historyFeedFilterProvider.notifier).state =
                      HistoryOutcomeFilter.completed;
                  ref
                      .read(historyFeedControllerProvider.notifier)
                      .setFilter(HistoryOutcomeFilter.completed);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Cancelled'),
                selected:
                    activeFilter == HistoryOutcomeFilter.interruptedOrCancelled,
                onSelected: (_) {
                  ref.read(historyFeedFilterProvider.notifier).state =
                      HistoryOutcomeFilter.interruptedOrCancelled;
                  ref
                      .read(historyFeedControllerProvider.notifier)
                      .setFilter(HistoryOutcomeFilter.interruptedOrCancelled);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: feedState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error loading sessions: $err')),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No session history found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return SessionFeedTile(
                    session: session,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => SessionDetailSheet(session: session),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

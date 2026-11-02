import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import '../../providers/history_providers.dart';
import 'manual_session_sheet.dart';
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
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Completed'),
                selected: activeFilter == HistoryOutcomeFilter.completed,
                onSelected: (_) {
                  ref.read(historyFeedFilterProvider.notifier).state =
                      HistoryOutcomeFilter.completed;
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
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_task),
                tooltip: 'Log Past Session',
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => const ManualSessionSheet(),
                  );
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

              final Map<String, List<SessionRecord>> grouped = {};
              for (final s in sessions) {
                final localDate = s.startedAtUtc.toLocal();
                final key = DateFormat('yyyy-MM-dd').format(localDate);
                grouped.putIfAbsent(key, () => []).add(s);
              }

              final sortedKeys = grouped.keys.toList();
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: sortedKeys.length,
                itemBuilder: (context, sectionIdx) {
                  final key = sortedKeys[sectionIdx];
                  final daySessions = grouped[key]!;
                  final sectionDate = daySessions.first.startedAtUtc.toLocal();
                  final headerText = _getDateHeader(sectionDate);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        child: Text(
                          headerText,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      ...daySessions.map((session) => SessionFeedTile(
                            session: session,
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) =>
                                    SessionDetailSheet(session: session),
                              );
                            },
                          )),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(sessionDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }
}

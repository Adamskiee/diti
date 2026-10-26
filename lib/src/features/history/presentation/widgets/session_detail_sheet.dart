import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'package:intl/intl.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../providers/history_providers.dart';
import 'session_app_breakdown_card.dart';

class SessionDetailSheet extends ConsumerWidget {
  final SessionRecord session;

  const SessionDetailSheet({
    super.key,
    required this.session,
  });

  String _formatOutcome(SessionOutcome outcome) {
    final name = outcome.name;
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localStart = session.startedAtUtc.toLocal();
    final localEnd = session.endedAtUtc.toLocal();

    final isCompleted = session.outcome == SessionOutcome.completed;
    final outcomeColor =
        isCompleted ? const Color(0xFF006C50) : const Color(0xFFBA1A1A);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        // The sheet's chrome - the handle, the title, the detail rows and
        // the action button - stays outside every scrollable, so dragging it
        // down dismisses the sheet the way the handle promises. Only the
        // phase log scrolls.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.routineName.trim().isEmpty
                        ? 'Quick Timer'
                        : session.routineName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatOutcome(session.outcome),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: outcomeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // The phase log can swallow a drag, so the sheet carries an
                // explicit close: dismissing it never depends on a gesture.
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Duration',
              DurationFormatter.formatMs(session.totalDurationMs),
              isDuration: true,
            ),
            _buildDetailRow(
              'Started',
              DateFormat('MMM d, y · h:mm:ss a').format(localStart),
            ),
            _buildDetailRow(
              'Ended',
              DateFormat('MMM d, y · h:mm:ss a').format(localEnd),
            ),
            if (session.planBlockId != null)
              _buildDetailRow('Linked Block', session.planBlockId!),
            if (session.appUsages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SessionAppBreakdownCard(
                usages: session.appUsages
                    .map(
                      (u) => AppUsageSummary(
                        appName: u.appName,
                        category: u.category,
                        sampleTitle: u.sampleTitle,
                        durationMs: u.durationMs,
                      ),
                    )
                    .toList(),
                totalDurationMs: session.totalDurationMs,
              ),
            ],
            if (session.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Phase Log',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // The log is the sheet's only scrollable region. It takes the
              // space the chrome leaves it and scrolls on its own, so a long
              // log never overflows the sheet.
              Flexible(
                fit: FlexFit.loose,
                child: ListView.builder(
                  key: const Key('phase_log'),
                  primary: false,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: session.events.length,
                  itemBuilder: (context, index) =>
                      _buildPhaseRow(session.events[index], theme),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Session'),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One phase of the log: the phase's name, the kind of phase it ran as and
  /// the active time it took. The duration is the phase's own active time -
  /// pauses are not part of it.
  ///
  /// The kind is the one the phase was recorded with, so a phase renamed
  /// after the session keeps the kind it ran as. A phase the user abandoned
  /// is marked as skipped: the time it took still counts, but it must not
  /// read like a phase that ran to its end.
  Widget _buildPhaseRow(SessionEventRecord event, ThemeData theme) {
    final phaseTitle = event.phaseName ?? event.eventType;
    final isFocus = event.kind == PhaseKind.focus;
    final kindColor =
        isFocus ? theme.colorScheme.primary : theme.colorScheme.tertiary;
    final isSkipped = event.outcome == PhaseStatus.skipped.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              phaseTitle,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              isFocus ? 'Focus' : 'Rest',
              style: theme.textTheme.labelSmall?.copyWith(
                color: kindColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: kindColor.withAlpha(30),
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (isSkipped) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(
                'Skipped',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor:
                  theme.colorScheme.onSurfaceVariant.withAlpha(30),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
          const SizedBox(width: 12),
          Text(
            DurationFormatter.formatMs(event.durationMs),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isDuration = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFeatures:
                  isDuration ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session Record?'),
        content: const Text(
          'This will permanently remove this session from your history and analytics totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final historyController = ref.read(historyFeedControllerProvider.notifier);
              final analyticsController = ref.read(analyticsControllerProvider.notifier);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              await historyController.deleteSession(session.sessionId);
              await analyticsController.load();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Session record deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

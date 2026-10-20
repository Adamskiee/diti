import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../providers/history_providers.dart';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            if (session.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Phase Log',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...session.events.map((e) {
                final phaseTitle = e.phaseName ?? e.eventType;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(phaseTitle, style: theme.textTheme.bodySmall),
                      Text(
                        DurationFormatter.formatMs(e.durationMs),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
